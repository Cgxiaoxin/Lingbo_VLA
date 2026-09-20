#!/usr/bin/env python3
"""OpenSSH ProxyCommand: tunnel TCP via HTTP CONNECT proxy (default 127.0.0.1:17890)."""
from __future__ import annotations

import os
import select
import socket
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <host> <port>", file=sys.stderr)
        return 2
    host, port = sys.argv[1], int(sys.argv[2])
    proxy_host = os.environ.get("GIT_HTTP_PROXY_HOST", "127.0.0.1")
    proxy_port = int(os.environ.get("GIT_HTTP_PROXY_PORT", "17890"))

    sock = socket.create_connection((proxy_host, proxy_port), timeout=20)
    req = (
        f"CONNECT {host}:{port} HTTP/1.1\r\n"
        f"Host: {host}:{port}\r\n"
        f"Proxy-Connection: keep-alive\r\n"
        f"\r\n"
    ).encode()
    sock.sendall(req)

    buf = b""
    while b"\r\n\r\n" not in buf:
        chunk = sock.recv(4096)
        if not chunk:
            break
        buf += chunk
    status = buf.split(b"\r\n", 1)[0]
    if b" 200 " not in status and not status.endswith(b" 200"):
        sys.stderr.write(buf.decode(errors="replace"))
        return 1

    sock.setblocking(False)
    stdin = sys.stdin.buffer
    stdout = sys.stdout.buffer
    while True:
        r, _, _ = select.select([sock, stdin], [], [])
        if sock in r:
            data = sock.recv(65536)
            if not data:
                return 0
            stdout.write(data)
            stdout.flush()
        if stdin in r:
            data = stdin.read(65536)
            if not data:
                return 0
            sock.sendall(data)


if __name__ == "__main__":
    raise SystemExit(main())
