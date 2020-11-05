#
# BitBake Graphical GTK based Dependency Explorer
#
# Copyright (C) 2007        Ross Burton
# Copyright (C) 2007 - 2008 Richard Purdie
#
# SPDX-License-Identifier: GPL-2.0-only
#

import sys
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GObject
from multiprocessing import Queue
import threading
from xmlrpc import client
import time
import bb
import bb.event

# Package Model
(COL_PKG_NAME) = (0)

# Dependency Model
(TYPE_DEP, TYPE_RDEP) = (0, 1)
(COL_DEP_TYPE, COL_DEP_PARENT, COL_DEP_PACKAGE) = (0, 1, 2)


class PackageDepView(Gtk.TreeView):
    def __init__(self, model, dep_type, label):
        """
        Initialize a gtk tree

        Args:
            self: (todo): write your description
            model: (todo): write your description
            dep_type: (todo): write your description
            label: (str): write your description
        """
        Gtk.TreeView.__init__(self)
        self.current = None
        self.dep_type = dep_type
        self.filter_model = model.filter_new()
        self.filter_model.set_visible_func(self._filter, data=None)
        self.set_model(self.filter_model)
        self.append_column(Gtk.TreeViewColumn(label, Gtk.CellRendererText(), text=COL_DEP_PACKAGE))

    def _filter(self, model, iter, data):
        """
        Return true if the filter is filtered by the filter.

        Args:
            self: (todo): write your description
            model: (todo): write your description
            iter: (int): write your description
            data: (str): write your description
        """
        this_type = model[iter][COL_DEP_TYPE]
        package = model[iter][COL_DEP_PARENT]
        if this_type != self.dep_type: return False
        return package == self.current

    def set_current_package(self, package):
        """
        Set current package

        Args:
            self: (todo): write your description
            package: (str): write your description
        """
        self.current = package
        self.filter_model.refilter()


class PackageReverseDepView(Gtk.TreeView):
    def __init__(self, model, label):
        """
        Initialize gtk. gtk. gtk.

        Args:
            self: (todo): write your description
            model: (todo): write your description
            label: (str): write your description
        """
        Gtk.TreeView.__init__(self)
        self.current = None
        self.filter_model = model.filter_new()
        self.filter_model.set_visible_func(self._filter)
        self.sort_model = self.filter_model.sort_new_with_model()
        self.sort_model.set_sort_column_id(COL_DEP_PARENT, Gtk.SortType.ASCENDING)
        self.set_model(self.sort_model)
        self.append_column(Gtk.TreeViewColumn(label, Gtk.CellRendererText(), text=COL_DEP_PARENT))

    def _filter(self, model, iter, data):
        """
        Filter the given filter.

        Args:
            self: (todo): write your description
            model: (todo): write your description
            iter: (int): write your description
            data: (str): write your description
        """
        package = model[iter][COL_DEP_PACKAGE]
        return package == self.current

    def set_current_package(self, package):
        """
        Set current package

        Args:
            self: (todo): write your description
            package: (str): write your description
        """
        self.current = package
        self.filter_model.refilter()


class DepExplorer(Gtk.Window):
    def __init__(self):
        """
        Initialize the gtk.

        Args:
            self: (todo): write your description
        """
        Gtk.Window.__init__(self)
        self.set_title("Task Dependency Explorer")
        self.set_default_size(500, 500)
        self.connect("delete-event", Gtk.main_quit)

        # Create the data models
        self.pkg_model = Gtk.ListStore(GObject.TYPE_STRING)
        self.pkg_model.set_sort_column_id(COL_PKG_NAME, Gtk.SortType.ASCENDING)
        self.depends_model = Gtk.ListStore(GObject.TYPE_INT, GObject.TYPE_STRING, GObject.TYPE_STRING)
        self.depends_model.set_sort_column_id(COL_DEP_PACKAGE, Gtk.SortType.ASCENDING)

        pane = Gtk.HPaned()
        pane.set_position(250)
        self.add(pane)

        # The master list of packages
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.IN)

        self.pkg_treeview = Gtk.TreeView(self.pkg_model)
        self.pkg_treeview.get_selection().connect("changed", self.on_cursor_changed)
        column = Gtk.TreeViewColumn("Package", Gtk.CellRendererText(), text=COL_PKG_NAME)
        self.pkg_treeview.append_column(column)
        scrolled.add(self.pkg_treeview)

        self.search_entry = Gtk.SearchEntry.new()
        self.pkg_treeview.set_search_entry(self.search_entry)

        left_panel = Gtk.VPaned()
        left_panel.add(self.search_entry)
        left_panel.add(scrolled)
        pane.add1(left_panel)

        box = Gtk.VBox(homogeneous=True, spacing=4)

        # Task Depends
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.IN)
        self.dep_treeview = PackageDepView(self.depends_model, TYPE_DEP, "Dependencies")
        self.dep_treeview.connect("row-activated", self.on_package_activated, COL_DEP_PACKAGE)
        scrolled.add(self.dep_treeview)
        box.add(scrolled)
        pane.add2(box)

        # Reverse Task Depends
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_shadow_type(Gtk.ShadowType.IN)
        self.revdep_treeview = PackageReverseDepView(self.depends_model, "Dependent Tasks")
        self.revdep_treeview.connect("row-activated", self.on_package_activated, COL_DEP_PARENT)
        scrolled.add(self.revdep_treeview)
        box.add(scrolled)
        pane.add2(box)

        self.show_all()
        self.search_entry.grab_focus()

    def on_package_activated(self, treeview, path, column, data_col):
        """
        Callback method that column selection

        Args:
            self: (todo): write your description
            treeview: (todo): write your description
            path: (str): write your description
            column: (str): write your description
            data_col: (todo): write your description
        """
        model = treeview.get_model()
        package = model.get_value(model.get_iter(path), data_col)

        pkg_path = []
        def finder(model, path, iter, needle):
            """
            Return true if the given package is installed package.

            Args:
                model: (todo): write your description
                path: (str): write your description
                iter: (int): write your description
                needle: (todo): write your description
            """
            package = model.get_value(iter, COL_PKG_NAME)
            if package == needle:
                pkg_path.append(path)
                return True
            else:
                return False
        self.pkg_model.foreach(finder, package)
        if pkg_path:
            self.pkg_treeview.get_selection().select_path(pkg_path[0])
            self.pkg_treeview.scroll_to_cell(pkg_path[0])

    def on_cursor_changed(self, selection):
        """
        Called when the selected item

        Args:
            self: (todo): write your description
            selection: (todo): write your description
        """
        (model, it) = selection.get_selected()
        if it is None:
            current_package = None
        else:
            current_package = model.get_value(it, COL_PKG_NAME)
        self.dep_treeview.set_current_package(current_package)
        self.revdep_treeview.set_current_package(current_package)


    def parse(self, depgraph):
        """
        Parse the dependency dependencies.

        Args:
            self: (str): write your description
            depgraph: (str): write your description
        """
        for task in depgraph["tdepends"]:
            self.pkg_model.insert(0, (task,))
            for depend in depgraph["tdepends"][task]:
                self.depends_model.insert (0, (TYPE_DEP, task, depend))


class gtkthread(threading.Thread):
    quit = threading.Event()
    def __init__(self, shutdown):
        """
        Initialize the gtk instance.

        Args:
            self: (todo): write your description
            shutdown: (todo): write your description
        """
        threading.Thread.__init__(self)
        self.setDaemon(True)
        self.shutdown = shutdown
        if not Gtk.init_check()[0]:
            sys.stderr.write("Gtk+ init failed. Make sure DISPLAY variable is set.\n")
            gtkthread.quit.set()

    def run(self):
        """
        Run gtk thread

        Args:
            self: (todo): write your description
        """
        GObject.threads_init()
        Gdk.threads_init()
        Gtk.main()
        gtkthread.quit.set()


def main(server, eventHandler, params):
    """
    Main function.

    Args:
        server: (todo): write your description
        eventHandler: (todo): write your description
        params: (dict): write your description
    """
    shutdown = 0

    gtkgui = gtkthread(shutdown)
    gtkgui.start()

    try:
        params.updateFromServer(server)
        cmdline = params.parseActions()
        if not cmdline:
            print("Nothing to do.  Use 'bitbake world' to build everything, or run 'bitbake --help' for usage information.")
            return 1
        if 'msg' in cmdline and cmdline['msg']:
            print(cmdline['msg'])
            return 1
        cmdline = cmdline['action']
        if not cmdline or cmdline[0] != "generateDotGraph":
            print("This UI requires the -g option")
            return 1
        ret, error = server.runCommand(["generateDepTreeEvent", cmdline[1], cmdline[2]])
        if error:
            print("Error running command '%s': %s" % (cmdline, error))
            return 1
        elif ret != True:
            print("Error running command '%s': returned %s" % (cmdline, ret))
            return 1
    except client.Fault as x:
        print("XMLRPC Fault getting commandline:\n %s" % x)
        return

    if gtkthread.quit.isSet():
        return

    Gdk.threads_enter()
    dep = DepExplorer()
    bardialog = Gtk.Dialog(parent=dep,
            flags=Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT)
    bardialog.set_default_size(400, 50)
    box = bardialog.get_content_area()
    pbar = Gtk.ProgressBar()
    box.pack_start(pbar, True, True, 0)
    bardialog.show_all()
    bardialog.connect("delete-event", Gtk.main_quit)
    Gdk.threads_leave()

    progress_total = 0
    while True:
        try:
            event = eventHandler.waitEvent(0.25)
            if gtkthread.quit.isSet():
                _, error = server.runCommand(["stateForceShutdown"])
                if error:
                    print('Unable to cleanly stop: %s' % error)
                break

            if event is None:
                continue

            if isinstance(event, bb.event.CacheLoadStarted):
                progress_total = event.total
                Gdk.threads_enter()
                bardialog.set_title("Loading Cache")
                pbar.set_fraction(0.0)
                Gdk.threads_leave()

            if isinstance(event, bb.event.CacheLoadProgress):
                x = event.current
                Gdk.threads_enter()
                pbar.set_fraction(x * 1.0 / progress_total)
                Gdk.threads_leave()
                continue

            if isinstance(event, bb.event.CacheLoadCompleted):
                continue

            if isinstance(event, bb.event.ParseStarted):
                progress_total = event.total
                if progress_total == 0:
                    continue
                Gdk.threads_enter()
                pbar.set_fraction(0.0)
                bardialog.set_title("Processing recipes")
                Gdk.threads_leave()

            if isinstance(event, bb.event.ParseProgress):
                x = event.current
                Gdk.threads_enter()
                pbar.set_fraction(x * 1.0 / progress_total)
                Gdk.threads_leave()
                continue

            if isinstance(event, bb.event.ParseCompleted):
                Gdk.threads_enter()
                bardialog.set_title("Generating dependency tree")
                Gdk.threads_leave()
                continue

            if isinstance(event, bb.event.DepTreeGenerated):
                Gdk.threads_enter()
                bardialog.hide()
                dep.parse(event._depgraph)
                Gdk.threads_leave()

            if isinstance(event, bb.command.CommandCompleted):
                continue

            if isinstance(event, bb.event.NoProvider):
                print(str(event))

                _, error = server.runCommand(["stateShutdown"])
                if error:
                    print('Unable to cleanly shutdown: %s' % error)
                break

            if isinstance(event, bb.command.CommandFailed):
                print(str(event))
                return event.exitcode

            if isinstance(event, bb.command.CommandExit):
                return event.exitcode

            if isinstance(event, bb.cooker.CookerExit):
                break

            continue
        except EnvironmentError as ioerror:
            # ignore interrupted io
            if ioerror.args[0] == 4:
                pass
        except KeyboardInterrupt:
            if shutdown == 2:
                print("\nThird Keyboard Interrupt, exit.\n")
                break
            if shutdown == 1:
                print("\nSecond Keyboard Interrupt, stopping...\n")
                _, error = server.runCommand(["stateForceShutdown"])
                if error:
                    print('Unable to cleanly stop: %s' % error)
            if shutdown == 0:
                print("\nKeyboard Interrupt, closing down...\n")
                _, error = server.runCommand(["stateShutdown"])
                if error:
                    print('Unable to cleanly shutdown: %s' % error)
            shutdown = shutdown + 1
            pass
