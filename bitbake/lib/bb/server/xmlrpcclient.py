#
# BitBake XMLRPC Client Interface
#
# Copyright (C) 2006 - 2007  Michael 'Mickey' Lauer
# Copyright (C) 2006 - 2008  Richard Purdie
#
# SPDX-License-Identifier: GPL-2.0-only
#

import os
import sys

import socket
import http.client
import xmlrpc.client

import bb
from bb.ui import uievent

class BBTransport(xmlrpc.client.Transport):
    def __init__(self, timeout):
        """
        Establish a new connection.

        Args:
            self: (todo): write your description
            timeout: (int): write your description
        """
        self.timeout = timeout
        self.connection_token = None
        xmlrpc.client.Transport.__init__(self)

    # Modified from default to pass timeout to HTTPConnection
    def make_connection(self, host):
        """
        Make a http connection.

        Args:
            self: (todo): write your description
            host: (str): write your description
        """
        #return an existing connection if possible.  This allows
        #HTTP/1.1 keep-alive.
        if self._connection and host == self._connection[0]:
            return self._connection[1]

        # create a HTTP connection object from a host descriptor
        chost, self._extra_headers, x509 = self.get_host_info(host)
        #store the host argument along with the connection object
        self._connection = host, http.client.HTTPConnection(chost, timeout=self.timeout)
        return self._connection[1]

    def set_connection_token(self, token):
        """
        Set the connection token.

        Args:
            self: (todo): write your description
            token: (str): write your description
        """
        self.connection_token = token

    def send_content(self, h, body):
        """
        Send a message to the h

        Args:
            self: (todo): write your description
            h: (todo): write your description
            body: (str): write your description
        """
        if self.connection_token:
            h.putheader("Bitbake-token", self.connection_token)
        xmlrpc.client.Transport.send_content(self, h, body)

def _create_server(host, port, timeout = 60):
    """
    Create a server.

    Args:
        host: (str): write your description
        port: (int): write your description
        timeout: (float): write your description
    """
    t = BBTransport(timeout)
    s = xmlrpc.client.ServerProxy("http://%s:%d/" % (host, port), transport=t, allow_none=True, use_builtin_types=True)
    return s, t

def check_connection(remote, timeout):
    """
    Check if a connection is established.

    Args:
        remote: (str): write your description
        timeout: (int): write your description
    """
    try:
        host, port = remote.split(":")
        port = int(port)
    except Exception as e:
        bb.warn("Failed to read remote definition (%s)" % str(e))
        raise e

    server, _transport = _create_server(host, port, timeout)
    try:
        ret, err =  server.runCommand(['getVariable', 'TOPDIR'])
        if err or not ret:
            return False
    except ConnectionError:
        return False
    return True

class BitBakeXMLRPCServerConnection(object):
    def __init__(self, host, port, clientinfo=("localhost", 0), observer_only = False, featureset = None):
        """
        Initialize the client.

        Args:
            self: (todo): write your description
            host: (str): write your description
            port: (int): write your description
            clientinfo: (todo): write your description
            observer_only: (todo): write your description
            featureset: (todo): write your description
        """
        self.connection, self.transport = _create_server(host, port)
        self.clientinfo = clientinfo
        self.observer_only = observer_only
        if featureset:
            self.featureset = featureset
        else:
            self.featureset = []

        self.events = uievent.BBUIEventQueue(self.connection, self.clientinfo)

        _, error = self.connection.runCommand(["setFeatures", self.featureset])
        if error:
            # disconnect the client, we can't make the setFeature work
            self.connection.removeClient()
            # no need to log it here, the error shall be sent to the client
            raise BaseException(error)

    def connect(self, token = None):
        """
        Connect to the server.

        Args:
            self: (todo): write your description
            token: (str): write your description
        """
        if token is None:
            if self.observer_only:
                token = "observer"
            else:
                token = self.connection.addClient()

        if token is None:
            return None

        self.transport.set_connection_token(token)
        return self

    def removeClient(self):
        """
        Removes an observer.

        Args:
            self: (todo): write your description
        """
        if not self.observer_only:
            self.connection.removeClient()

    def terminate(self):
        """
        Terminate the socket.

        Args:
            self: (todo): write your description
        """
        # Don't wait for server indefinitely
        socket.setdefaulttimeout(2)
        try:
            self.events.system_quit()
        except:
            pass
        try:
            self.connection.removeClient()
        except:
            pass

def connectXMLRPC(remote, featureset, observer_only = False, token = None):
    """
    Connect to a connection.

    Args:
        remote: (str): write your description
        featureset: (bool): write your description
        observer_only: (todo): write your description
        token: (str): write your description
    """
    # The format of "remote" must be "server:port"
    try:
        [host, port] = remote.split(":")
        port = int(port)
    except Exception as e:
        bb.warn("Failed to parse remote definition %s (%s)" % (remote, str(e)))
        raise e

    # We need our IP for the server connection. We get the IP
    # by trying to connect with the server
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect((host, port))
        ip = s.getsockname()[0]
        s.close()
    except Exception as e:
        bb.warn("Could not create socket for %s:%s (%s)" % (host, port, str(e)))
        raise e
    try:
        connection = BitBakeXMLRPCServerConnection(host, port, (ip, 0), observer_only, featureset)
        return connection.connect(token)
    except Exception as e:
        bb.warn("Could not connect to server at %s:%s (%s)" % (host, port, str(e)))
        raise e



