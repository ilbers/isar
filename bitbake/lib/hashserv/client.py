# Copyright (C) 2019 Garmin Ltd.
#
# SPDX-License-Identifier: GPL-2.0-only
#

from contextlib import closing
import json
import logging
import socket
import os


logger = logging.getLogger('hashserv.client')


class HashConnectionError(Exception):
    pass


class Client(object):
    MODE_NORMAL = 0
    MODE_GET_STREAM = 1

    def __init__(self):
        """
        Initialize the socket.

        Args:
            self: (todo): write your description
        """
        self._socket = None
        self.reader = None
        self.writer = None
        self.mode = self.MODE_NORMAL

    def connect_tcp(self, address, port):
        """
        Connect to a tcp socket.

        Args:
            self: (todo): write your description
            address: (str): write your description
            port: (int): write your description
        """
        def connect_sock():
            """
            Connect to a socket.

            Args:
            """
            s = socket.create_connection((address, port))

            s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
            s.setsockopt(socket.SOL_TCP, socket.TCP_QUICKACK, 1)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
            return s

        self._connect_sock = connect_sock

    def connect_unix(self, path):
        """
        Connect to a unix socket.

        Args:
            self: (todo): write your description
            path: (str): write your description
        """
        def connect_sock():
            """
            Connect to a socket.

            Args:
            """
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            # AF_UNIX has path length issues so chdir here to workaround
            cwd = os.getcwd()
            try:
                os.chdir(os.path.dirname(path))
                s.connect(os.path.basename(path))
            finally:
                os.chdir(cwd)
            return s

        self._connect_sock = connect_sock

    def connect(self):
        """
        Connect to the socket.

        Args:
            self: (todo): write your description
        """
        if self._socket is None:
            self._socket = self._connect_sock()

            self.reader = self._socket.makefile('r', encoding='utf-8')
            self.writer = self._socket.makefile('w', encoding='utf-8')

            self.writer.write('OEHASHEQUIV 1.0\n\n')
            self.writer.flush()

            # Restore mode if the socket is being re-created
            cur_mode = self.mode
            self.mode = self.MODE_NORMAL
            self._set_mode(cur_mode)

        return self._socket

    def close(self):
        """
        Closes the socket.

        Args:
            self: (todo): write your description
        """
        if self._socket is not None:
            self._socket.close()
            self._socket = None
            self.reader = None
            self.writer = None

    def _send_wrapper(self, proc):
        """
        Sends a connection to the socket.

        Args:
            self: (todo): write your description
            proc: (todo): write your description
        """
        count = 0
        while True:
            try:
                self.connect()
                return proc()
            except (OSError, HashConnectionError, json.JSONDecodeError, UnicodeDecodeError) as e:
                logger.warning('Error talking to server: %s' % e)
                if count >= 3:
                    if not isinstance(e, HashConnectionError):
                        raise HashConnectionError(str(e))
                    raise e
                self.close()
                count += 1

    def send_message(self, msg):
        """
        Send a message to the server.

        Args:
            self: (todo): write your description
            msg: (str): write your description
        """
        def proc():
            """
            Read the json string.

            Args:
            """
            self.writer.write('%s\n' % json.dumps(msg))
            self.writer.flush()

            l = self.reader.readline()
            if not l:
                raise HashConnectionError('Connection closed')

            if not l.endswith('\n'):
                raise HashConnectionError('Bad message %r' % message)

            return json.loads(l)

        return self._send_wrapper(proc)

    def send_stream(self, msg):
        """
        Send a message to the socket.

        Args:
            self: (todo): write your description
            msg: (str): write your description
        """
        def proc():
            """
            Reads the next byte string.

            Args:
            """
            self.writer.write("%s\n" % msg)
            self.writer.flush()
            l = self.reader.readline()
            if not l:
                raise HashConnectionError('Connection closed')
            return l.rstrip()

        return self._send_wrapper(proc)

    def _set_mode(self, new_mode):
        """
        Set the mode.

        Args:
            self: (todo): write your description
            new_mode: (str): write your description
        """
        if new_mode == self.MODE_NORMAL and self.mode == self.MODE_GET_STREAM:
            r = self.send_stream('END')
            if r != 'ok':
                raise HashConnectionError('Bad response from server %r' % r)
        elif new_mode == self.MODE_GET_STREAM and self.mode == self.MODE_NORMAL:
            r = self.send_message({'get-stream': None})
            if r != 'ok':
                raise HashConnectionError('Bad response from server %r' % r)
        elif new_mode != self.mode:
            raise Exception('Undefined mode transition %r -> %r' % (self.mode, new_mode))

        self.mode = new_mode

    def get_unihash(self, method, taskhash):
        """
        Get unihash from the given method.

        Args:
            self: (todo): write your description
            method: (str): write your description
            taskhash: (str): write your description
        """
        self._set_mode(self.MODE_GET_STREAM)
        r = self.send_stream('%s %s' % (method, taskhash))
        if not r:
            return None
        return r

    def report_unihash(self, taskhash, method, outhash, unihash, extra={}):
        """
        Report unihash.

        Args:
            self: (todo): write your description
            taskhash: (todo): write your description
            method: (str): write your description
            outhash: (todo): write your description
            unihash: (str): write your description
            extra: (array): write your description
        """
        self._set_mode(self.MODE_NORMAL)
        m = extra.copy()
        m['taskhash'] = taskhash
        m['method'] = method
        m['outhash'] = outhash
        m['unihash'] = unihash
        return self.send_message({'report': m})

    def get_stats(self):
        """
        Returns the stats to be sentry.

        Args:
            self: (todo): write your description
        """
        self._set_mode(self.MODE_NORMAL)
        return self.send_message({'get-stats': None})

    def reset_stats(self):
        """
        Reset the stats.

        Args:
            self: (todo): write your description
        """
        self._set_mode(self.MODE_NORMAL)
        return self.send_message({'reset-stats': None})
