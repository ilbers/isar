# Copyright (C) 2016-2018 Wind River Systems, Inc.
#
# SPDX-License-Identifier: GPL-2.0-only
#
# The file contains:
#   LayerIndex exceptions
#   Plugin base class
#   Utility Functions for working on layerindex data

import argparse
import logging
import os
import bb.msg

logger = logging.getLogger('BitBake.layerindexlib.plugin')

class LayerIndexPluginException(Exception):
    """LayerIndex Generic Exception"""
    def __init__(self, message):
        """
        Initialize the message

        Args:
            self: (todo): write your description
            message: (str): write your description
        """
         self.msg = message
         Exception.__init__(self, message)

    def __str__(self):
        """
        Return a string representation of the message.

        Args:
            self: (todo): write your description
        """
         return self.msg

class LayerIndexPluginUrlError(LayerIndexPluginException):
    """Exception raised when a plugin does not support a given URL type"""
    def __init__(self, plugin, url):
        """
        Initialize the plugin.

        Args:
            self: (todo): write your description
            plugin: (todo): write your description
            url: (str): write your description
        """
        msg = "%s does not support %s:" % (plugin, url)
        self.plugin = plugin
        self.url = url
        LayerIndexPluginException.__init__(self, msg)

class IndexPlugin():
    def __init__(self):
        """
        Initialize the object

        Args:
            self: (todo): write your description
        """
        self.type = None

    def init(self, layerindex):
        """
        Initialize layerindex.

        Args:
            self: (todo): write your description
            layerindex: (todo): write your description
        """
        self.layerindex = layerindex

    def plugin_type(self):
        """
        Returns the plugin type.

        Args:
            self: (todo): write your description
        """
        return self.type

    def load_index(self, uri):
        """
        Load an index of a given uri.

        Args:
            self: (str): write your description
            uri: (str): write your description
        """
        raise NotImplementedError('load_index is not implemented')

    def store_index(self, uri, index):
        """
        Store an index for the given index.

        Args:
            self: (todo): write your description
            uri: (str): write your description
            index: (int): write your description
        """
        raise NotImplementedError('store_index is not implemented')

