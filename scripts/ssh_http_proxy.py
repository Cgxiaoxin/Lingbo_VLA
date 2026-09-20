#!/usr/bin/env python3
"""OpenSSH ProxyCommand: tunnel TCP via HTTP CONNECT (default 127.0.0.1:17890)."""
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
    sock.sendall(
        (
            f"CONNECT {host}:{port} HTTP/1.0\r\n"
            f"Host: {host}:{port}\r\n"
            f"\r\n"
        ).encode()
    )

    buf = b""
    sock.settimeout(20)
    while b"\r\n\r\n" not in buf:
        chunk = sock.recv(4096)
        if not chunk:
            sys.stderr.write("proxy closed before CONNECT response\n")
            return 1
        buf += chunk

    header, leftover = buf.split(b"\r\n\r\n", 1)
    status_line = header.split(b"\r\n", 1)[0]
    if b"200" not in status_line:
        sys.stderr.write(header.decode(errors="replace") + "\n")
        return 1

    # OpenSSH talks to us over stdin/stdout pipes
    stdin_fd = sys.stdin.fileno()
    stdout_fd = sys.stdout.fileno()
    sock_fd = sock.fileno()

    if leftover:
        os.write(stdout_fd, leftover)

    sock.settimeout(None)
    sock.setblocking(False)
    os.set_blocking(stdin_fd, False)

    try:
        while True:
            r, _, x = select.select([sock_fd, stdin_fd], [], [sock_fd, stdin_fd], 60.0)
            if x:
                return 1
            if not r:
                sys.stderr.write("proxy tunnel idle timeout\n")
                return 1
            if sock_fd in r:
                try:
                    data = sock.recv(65536)
                except BlockingIOError:
                    data = b""
                if not data:
                    return 0
                os.write(stdout_fd, data)
            if stdin_fd in r:
                try:
                    data = os.read(stdin_fd, 65536)
                except BlockingIOError:
                    data = b""
                if not data:
                    return 0
                sock.sendall(data)
    finally:
        try:
            sock.close()
        except OSError:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
