#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# =====================================================================
#  Arandu - Ajudante de Saude do Sistema (MULTIPLATAFORMA)
# ---------------------------------------------------------------------
#  Equivalente Python do saude_sistema.ps1, para Linux e macOS
#  (tambem roda no Windows como alternativa).
#
#  MESMO CONTRATO HTTP do helper PowerShell, entao o Painel_Saude.html
#  e o mini painel funcionam sem nenhuma alteracao:
#     /saude    -> RAM, discos, CPU, uptime
#     /limpeza  -> arquivos limpaveis com tamanho (NAO apaga nada)
#     /agenda   -> (por enquanto) aviso "ainda nao neste SO"
#     /email    -> (por enquanto) aviso "ainda nao neste SO"
#     /ping     -> teste de vida
#
#  SEGURANCA: escuta SO em 127.0.0.1. Somente leitura. So usa stdlib.
#
#  Uso:  python3 saude_sistema.py
#        (os lancadores iniciar.sh fazem isso por voce)
# =====================================================================

import os
import sys
import time
import json
import platform
import datetime
import subprocess
import shutil
import http.server
import socketserver

PORTA = 8099
SO = platform.system()  # 'Linux', 'Darwin' (macOS) ou 'Windows'


def agora():
    return datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')


# ---------------- coleta de metricas ----------------

def ram_info():
    total = livre = None
    try:
        if SO == 'Linux':
            d = {}
            with open('/proc/meminfo') as f:
                for linha in f:
                    chave, _, valor = linha.partition(':')
                    d[chave.strip()] = valor.strip()
            kb = lambda k: int(d[k].split()[0]) * 1024
            total = kb('MemTotal')
            livre = kb('MemAvailable') if 'MemAvailable' in d else kb('MemFree')

        elif SO == 'Darwin':
            total = int(subprocess.check_output(['sysctl', '-n', 'hw.memsize']).strip())
            saida = subprocess.check_output(['vm_stat']).decode('utf-8', 'ignore')
            page = 4096
            m = {}
            for linha in saida.splitlines():
                if 'page size of' in linha:
                    try:
                        page = int(linha.split('page size of')[1].split('bytes')[0].strip())
                    except Exception:
                        pass
                if ':' in linha:
                    chave, _, valor = linha.partition(':')
                    m[chave.strip()] = valor.strip().rstrip('.')
            paginas = lambda k: int(m.get(k, '0') or '0')
            livres = paginas('Pages free') + paginas('Pages inactive') + paginas('Pages speculative')
            livre = livres * page

        elif SO == 'Windows':
            import ctypes

            class MEMSTAT(ctypes.Structure):
                _fields_ = [('dwLength', ctypes.c_ulong),
                            ('dwMemoryLoad', ctypes.c_ulong),
                            ('ullTotalPhys', ctypes.c_ulonglong),
                            ('ullAvailPhys', ctypes.c_ulonglong),
                            ('ullTotalPageFile', ctypes.c_ulonglong),
                            ('ullAvailPageFile', ctypes.c_ulonglong),
                            ('ullTotalVirtual', ctypes.c_ulonglong),
                            ('ullAvailVirtual', ctypes.c_ulonglong),
                            ('ullAvailExtendedVirtual', ctypes.c_ulonglong)]

            ms = MEMSTAT()
            ms.dwLength = ctypes.sizeof(MEMSTAT)
            ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(ms))
            total = ms.ullTotalPhys
            livre = ms.ullAvailPhys
    except Exception:
        return None

    if not total:
        return None
    usado = total - livre
    pct = round(usado / total * 100, 1) if total else 0
    return {
        'total_gb': round(total / 1024 ** 3, 2),
        'livre_gb': round(livre / 1024 ** 3, 2),
        'usado_gb': round(usado / 1024 ** 3, 2),
        'usado_pct': pct,
    }


def _disco(nome, uso):
    usado = uso.total - uso.free
    pct = round(usado / uso.total * 100, 1) if uso.total else 0
    return {
        'unidade': nome,
        'total_gb': round(uso.total / 1024 ** 3, 1),
        'livre_gb': round(uso.free / 1024 ** 3, 1),
        'usado_gb': round(usado / 1024 ** 3, 1),
        'usado_pct': pct,
    }


def discos_info():
    discos = []
    if SO == 'Windows':
        import string
        for letra in string.ascii_uppercase:
            raiz = letra + ':\\'
            if os.path.exists(raiz):
                try:
                    discos.append(_disco(letra + ':', shutil.disk_usage(raiz)))
                except Exception:
                    pass
    else:
        # Linux/macOS: o volume raiz cobre o caso comum
        for ponto in ('/',):
            try:
                discos.append(_disco(ponto, shutil.disk_usage(ponto)))
            except Exception:
                pass
    return discos


def cpu_pct():
    try:
        if SO == 'Linux':
            def snap():
                with open('/proc/stat') as f:
                    partes = list(map(int, f.readline().split()[1:]))
                ocioso = partes[3] + (partes[4] if len(partes) > 4 else 0)
                return ocioso, sum(partes)
            i1, t1 = snap()
            time.sleep(0.25)
            i2, t2 = snap()
            dt = t2 - t1
            if dt <= 0:
                return None
            return round((1 - (i2 - i1) / dt) * 100)
        else:
            # macOS (e fallback): carga media / nucleos -> proxy de uso de CPU
            carga = os.getloadavg()[0]
            n = os.cpu_count() or 1
            return min(100, round(carga / n * 100))
    except Exception:
        return None


def uptime_horas():
    try:
        if SO == 'Linux':
            with open('/proc/uptime') as f:
                return round(float(f.readline().split()[0]) / 3600, 1)
        elif SO == 'Darwin':
            saida = subprocess.check_output(['sysctl', '-n', 'kern.boottime']).decode('utf-8', 'ignore')
            seg = int(saida.split('sec =')[1].split(',')[0].strip())
            return round((time.time() - seg) / 3600, 1)
        elif SO == 'Windows':
            import ctypes
            ms = ctypes.windll.kernel32.GetTickCount64()
            return round(ms / 1000.0 / 3600.0, 1)
    except Exception:
        return None
    return None


def saude_info():
    cpu = cpu_pct()
    return {
        'hostname': platform.node(),
        'coletado_em': agora(),
        'so': SO,
        'ram': ram_info() or {'total_gb': 0, 'livre_gb': 0, 'usado_gb': 0, 'usado_pct': 0},
        'discos': discos_info(),
        'cpu_pct': cpu if cpu is not None else 0,
        'uptime_horas': uptime_horas(),
    }


# ---------------- limpeza ----------------

def tamanho_mb(caminho):
    if not caminho or not os.path.isdir(caminho):
        return 0.0
    total = 0
    for raiz, _dirs, arquivos in os.walk(caminho, onerror=lambda e: None):
        for nome in arquivos:
            fp = os.path.join(raiz, nome)
            try:
                if not os.path.islink(fp):
                    total += os.path.getsize(fp)
            except OSError:
                pass
    return round(total / 1024 ** 2, 1)


def downloads_antigos_mb(caminho, dias):
    if not os.path.isdir(caminho):
        return 0.0
    corte = time.time() - dias * 86400
    total = 0
    for raiz, _dirs, arquivos in os.walk(caminho, onerror=lambda e: None):
        for nome in arquivos:
            fp = os.path.join(raiz, nome)
            try:
                if not os.path.islink(fp) and os.path.getmtime(fp) < corte:
                    total += os.path.getsize(fp)
            except OSError:
                pass
    return round(total / 1024 ** 2, 1)


def limpeza_info():
    home = os.path.expanduser('~')
    itens = []

    def add(nome, caminho, seguro, desc):
        itens.append({
            'nome': nome, 'caminho': caminho,
            'tamanho_mb': tamanho_mb(caminho),
            'seguro': seguro, 'descricao': desc,
        })

    if SO == 'Linux':
        add('Cache do usuário', os.path.join(home, '.cache'), True, 'Cache de aplicativos. Seguro de limpar.')
        add('Lixeira', os.path.join(home, '.local/share/Trash/files'), True, 'Itens na lixeira. Confira antes de esvaziar.')
        add('Temporários (/tmp)', '/tmp', True, 'Apagados ao reiniciar. Seguro.')
        add('Miniaturas (thumbnails)', os.path.join(home, '.cache/thumbnails'), True, 'Miniaturas recriadas pelo sistema.')
    elif SO == 'Darwin':
        add('Caches do usuário', os.path.join(home, 'Library/Caches'), True, 'Cache de aplicativos. Seguro de limpar.')
        add('Lixeira', os.path.join(home, '.Trash'), True, 'Itens na lixeira. Confira antes de esvaziar.')
        add('Logs do usuário', os.path.join(home, 'Library/Logs'), True, 'Logs de aplicativos.')
    elif SO == 'Windows':
        add('Temporários (usuário)', os.environ.get('TEMP', ''), True, 'Cache temporário. Seguro de limpar.')
        add('Lixeira', os.path.join(os.environ.get('SystemDrive', 'C:') + os.sep, '$Recycle.Bin'), True, 'Itens na lixeira.')

    downloads = os.path.join(home, 'Downloads')
    itens.append({
        'nome': 'Downloads com mais de 90 dias', 'caminho': downloads,
        'tamanho_mb': downloads_antigos_mb(downloads, 90),
        'seguro': False, 'descricao': 'Pode conter arquivos pessoais. Revise um a um antes de apagar.',
    })

    total = round(sum(i['tamanho_mb'] for i in itens), 1)
    seguro = round(sum(i['tamanho_mb'] for i in itens if i['seguro']), 1)
    return {
        'coletado_em': agora(), 'itens': itens,
        'total_mb': total, 'total_seguro_mb': seguro,
        'observacao': 'Nada foi apagado. Esta é apenas uma análise de leitura.',
    }


# ---------------- agenda / e-mail (stubs por SO) ----------------

def _dica_pim():
    if SO == 'Darwin':
        return 'Em desenvolvimento para macOS (Calendar.app / Mail.app via AppleScript).'
    if SO == 'Linux':
        return 'Em desenvolvimento para Linux (Thunderbird / Evolution / arquivos .ics).'
    return 'Disponível no Windows com o Outlook clássico.'


def agenda_info():
    return {'erro': 'Agenda ainda não disponível neste sistema.', 'dica': _dica_pim()}


def email_info():
    return {'erro': 'E-mail ainda não disponível neste sistema.', 'dica': _dica_pim()}


# ---------------- servidor HTTP ----------------

class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, obj, status=200):
        corpo = json.dumps(obj, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def do_GET(self):
        rota = self.path.split('?')[0].rstrip('/').lower() or '/'
        try:
            if rota == '/saude':
                self._send(saude_info())
            elif rota == '/limpeza':
                self._send(limpeza_info())
            elif rota == '/agenda':
                self._send(agenda_info())
            elif rota == '/email':
                self._send(email_info())
            elif rota in ('/ping', '/'):
                self._send({'ok': True, 'servico': 'arandu-saude', 'porta': PORTA, 'so': SO})
            else:
                self._send({'erro': 'rota desconhecida',
                            'rotas': ['/saude', '/limpeza', '/agenda', '/email', '/ping']}, 404)
        except Exception as e:
            self._send({'erro': 'falha interna', 'detalhe': str(e)}, 500)

    def log_message(self, *args):
        pass  # silencia o log padrao no console


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    try:
        httpd = Server(('127.0.0.1', PORTA), Handler)
    except OSError as e:
        print('Nao foi possivel abrir a porta %d (ja em uso?): %s' % (PORTA, e))
        sys.exit(1)
    print('Ajudante de saude do Arandu (Python/%s) em http://127.0.0.1:%d/' % (SO, PORTA))
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
