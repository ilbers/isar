"""
BitBake 'Command' module

Provide an interface to interact with the bitbake server through 'commands'
"""

# Copyright (C) 2006-2007  Richard Purdie
#
# SPDX-License-Identifier: GPL-2.0-only
#

"""
The bitbake server takes 'commands' from its UI/commandline.
Commands are either synchronous or asynchronous.
Async commands return data to the client in the form of events.
Sync commands must only return data through the function return value
and must not trigger events, directly or indirectly.
Commands are queued in a CommandQueue
"""

from collections import OrderedDict, defaultdict

import bb.event
import bb.cooker
import bb.remotedata

class DataStoreConnectionHandle(object):
    def __init__(self, dsindex=0):
        """
        Initialize the index

        Args:
            self: (todo): write your description
            dsindex: (int): write your description
        """
        self.dsindex = dsindex

class CommandCompleted(bb.event.Event):
    pass

class CommandExit(bb.event.Event):
    def  __init__(self, exitcode):
         """
         Initialize the event loop.

         Args:
             self: (todo): write your description
             exitcode: (int): write your description
         """
        bb.event.Event.__init__(self)
        self.exitcode = int(exitcode)

class CommandFailed(CommandExit):
    def __init__(self, message):
        """
        Initialize an error message.

        Args:
            self: (todo): write your description
            message: (str): write your description
        """
        self.error = message
        CommandExit.__init__(self, 1)
    def __str__(self):
        """
        Return the string representation of the error.

        Args:
            self: (todo): write your description
        """
        return "Command execution failed: %s" % self.error

class CommandError(Exception):
    pass

class Command:
    """
    A queue of asynchronous commands for bitbake
    """
    def __init__(self, cooker):
        """
        Initialize datastores.

        Args:
            self: (todo): write your description
            cooker: (todo): write your description
        """
        self.cooker = cooker
        self.cmds_sync = CommandsSync()
        self.cmds_async = CommandsAsync()
        self.remotedatastores = bb.remotedata.RemoteDatastores(cooker)

        # FIXME Add lock for this
        self.currentAsyncCommand = None

    def runCommand(self, commandline, ro_only = False):
        """
        Run a command.

        Args:
            self: (todo): write your description
            commandline: (str): write your description
            ro_only: (bool): write your description
        """
        command = commandline.pop(0)
        if hasattr(CommandsSync, command):
            # Can run synchronous commands straight away
            command_method = getattr(self.cmds_sync, command)
            if ro_only:
                if not hasattr(command_method, 'readonly') or False == getattr(command_method, 'readonly'):
                    return None, "Not able to execute not readonly commands in readonly mode"
            try:
                self.cooker.process_inotify_updates()
                if getattr(command_method, 'needconfig', True):
                    self.cooker.updateCacheSync()
                result = command_method(self, commandline)
            except CommandError as exc:
                return None, exc.args[0]
            except (Exception, SystemExit):
                import traceback
                return None, traceback.format_exc()
            else:
                return result, None
        if self.currentAsyncCommand is not None:
            return None, "Busy (%s in progress)" % self.currentAsyncCommand[0]
        if command not in CommandsAsync.__dict__:
            return None, "No such command"
        self.currentAsyncCommand = (command, commandline)
        self.cooker.configuration.server_register_idlecallback(self.cooker.runCommands, self.cooker)
        return True, None

    def runAsyncCommand(self):
        """
        Run the command.

        Args:
            self: (todo): write your description
        """
        try:
            self.cooker.process_inotify_updates()
            if self.cooker.state in (bb.cooker.state.error, bb.cooker.state.shutdown, bb.cooker.state.forceshutdown):
                # updateCache will trigger a shutdown of the parser
                # and then raise BBHandledException triggering an exit
                self.cooker.updateCache()
                return False
            if self.currentAsyncCommand is not None:
                (command, options) = self.currentAsyncCommand
                commandmethod = getattr(CommandsAsync, command)
                needcache = getattr( commandmethod, "needcache" )
                if needcache and self.cooker.state != bb.cooker.state.running:
                    self.cooker.updateCache()
                    return True
                else:
                    commandmethod(self.cmds_async, self, options)
                    return False
            else:
                return False
        except KeyboardInterrupt as exc:
            self.finishAsyncCommand("Interrupted")
            return False
        except SystemExit as exc:
            arg = exc.args[0]
            if isinstance(arg, str):
                self.finishAsyncCommand(arg)
            else:
                self.finishAsyncCommand("Exited with %s" % arg)
            return False
        except Exception as exc:
            import traceback
            if isinstance(exc, bb.BBHandledException):
                self.finishAsyncCommand("")
            else:
                self.finishAsyncCommand(traceback.format_exc())
            return False

    def finishAsyncCommand(self, msg=None, code=None):
        """
        Called when a command is received.

        Args:
            self: (todo): write your description
            msg: (str): write your description
            code: (str): write your description
        """
        if msg or msg == "":
            bb.event.fire(CommandFailed(msg), self.cooker.data)
        elif code:
            bb.event.fire(CommandExit(code), self.cooker.data)
        else:
            bb.event.fire(CommandCompleted(), self.cooker.data)
        self.currentAsyncCommand = None
        self.cooker.finishcommand()

    def reset(self):
        """
        Reset the datastores.

        Args:
            self: (todo): write your description
        """
        self.remotedatastores = bb.remotedata.RemoteDatastores(self.cooker)

def split_mc_pn(pn):
    """
    Splits a string into a tuple of strings ) pairs ) pairs ) where the keys.

    Args:
        pn: (str): write your description
    """
    if pn.startswith("multiconfig:"):
        _, mc, pn = pn.split(":", 2)
        return (mc, pn)
    return ('', pn)

class CommandsSync:
    """
    A class of synchronous commands
    These should run quickly so as not to hurt interactive performance.
    These must not influence any running synchronous command.
    """

    def stateShutdown(self, command, params):
        """
        Trigger cooker 'shutdown' mode
        """
        command.cooker.shutdown(False)

    def stateForceShutdown(self, command, params):
        """
        Stop the cooker
        """
        command.cooker.shutdown(True)

    def getAllKeysWithFlags(self, command, params):
        """
        Returns a dump of the global state. Call with
        variable flags to be retrieved as params.
        """
        flaglist = params[0]
        return command.cooker.getAllKeysWithFlags(flaglist)
    getAllKeysWithFlags.readonly = True

    def getVariable(self, command, params):
        """
        Read the value of a variable from data
        """
        varname = params[0]
        expand = True
        if len(params) > 1:
            expand = (params[1] == "True")

        return command.cooker.data.getVar(varname, expand)
    getVariable.readonly = True

    def setVariable(self, command, params):
        """
        Set the value of variable in data
        """
        varname = params[0]
        value = str(params[1])
        command.cooker.extraconfigdata[varname] = value
        command.cooker.data.setVar(varname, value)

    def getSetVariable(self, command, params):
        """
        Read the value of a variable from data and set it into the datastore
        which effectively expands and locks the value.
        """
        varname = params[0]
        result = self.getVariable(command, params)
        command.cooker.data.setVar(varname, result)
        return result

    def setConfig(self, command, params):
        """
        Set the value of variable in configuration
        """
        varname = params[0]
        value = str(params[1])
        setattr(command.cooker.configuration, varname, value)

    def enableDataTracking(self, command, params):
        """
        Enable history tracking for variables
        """
        command.cooker.enableDataTracking()

    def disableDataTracking(self, command, params):
        """
        Disable history tracking for variables
        """
        command.cooker.disableDataTracking()

    def setPrePostConfFiles(self, command, params):
        """
        Sets the prefiles command. postfiles to the command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        prefiles = params[0].split()
        postfiles = params[1].split()
        command.cooker.configuration.prefile = prefiles
        command.cooker.configuration.postfile = postfiles
    setPrePostConfFiles.needconfig = False

    def matchFile(self, command, params):
        """
        Returns true if the given command matches the given command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        fMatch = params[0]
        return command.cooker.matchFile(fMatch)
    matchFile.needconfig = False

    def getUIHandlerNum(self, command, params):
        """
        Gets the currently - line parameters ]

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        return bb.event.get_uihandler()
    getUIHandlerNum.needconfig = False
    getUIHandlerNum.readonly = True

    def setEventMask(self, command, params):
        """
        Function path : debug event handler

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        handlerNum = params[0]
        llevel = params[1]
        debug_domains = params[2]
        mask = params[3]
        return bb.event.set_UIHmask(handlerNum, llevel, debug_domains, mask)
    setEventMask.needconfig = False
    setEventMask.readonly = True

    def setFeatures(self, command, params):
        """
        Set the cooker features to include the passed list of features
        """
        features = params[0]
        command.cooker.setFeatures(features)
    setFeatures.needconfig = False
    # although we change the internal state of the cooker, this is transparent since
    # we always take and leave the cooker in state.initial
    setFeatures.readonly = True

    def updateConfig(self, command, params):
        """
        Updates the command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (list): write your description
        """
        options = params[0]
        environment = params[1]
        cmdline = params[2]
        command.cooker.updateConfigOpts(options, environment, cmdline)
    updateConfig.needconfig = False

    def parseConfiguration(self, command, params):
        """Instruct bitbake to parse its configuration
        NOTE: it is only necessary to call this if you aren't calling any normal action
        (otherwise parsing is taken care of automatically)
        """
        command.cooker.parseConfiguration()
    parseConfiguration.needconfig = False

    def getLayerPriorities(self, command, params):
        """
        Parse a list from the command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        command.cooker.parseConfiguration()
        ret = []
        # regex objects cannot be marshalled by xmlrpc
        for collection, pattern, regex, pri in command.cooker.bbfile_config_priorities:
            ret.append((collection, pattern, regex.pattern, pri))
        return ret
    getLayerPriorities.readonly = True

    def getRecipes(self, command, params):
        """
        Returns a list of recipes.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return list(command.cooker.recipecaches[mc].pkg_pn.items())
    getRecipes.readonly = True

    def getRecipeDepends(self, command, params):
        """
        Return a list of recipes for the given command.

        Args:
            self: (todo): write your description
            command: (todo): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return list(command.cooker.recipecaches[mc].deps.items())
    getRecipeDepends.readonly = True

    def getRecipeVersions(self, command, params):
        """
        Returns a list of - packages for a given command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].pkg_pepvpr
    getRecipeVersions.readonly = True

    def getRecipeProvides(self, command, params):
        """
        Returns a list of recipes.

        Args:
            self: (todo): write your description
            command: (todo): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].fn_provides
    getRecipeProvides.readonly = True

    def getRecipePackages(self, command, params):
        """
        Returns a list of packages.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].packages
    getRecipePackages.readonly = True

    def getRecipePackagesDynamic(self, command, params):
        """
        Returns a list of recipes of a given command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].packages_dynamic
    getRecipePackagesDynamic.readonly = True

    def getRProviders(self, command, params):
        """
        Returns a list

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].rproviders
    getRProviders.readonly = True

    def getRuntimeDepends(self, command, params):
        """
        Return a list of recipes.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        ret = []
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        rundeps = command.cooker.recipecaches[mc].rundeps
        for key, value in rundeps.items():
            if isinstance(value, defaultdict):
                value = dict(value)
            ret.append((key, value))
        return ret
    getRuntimeDepends.readonly = True

    def getRuntimeRecommends(self, command, params):
        """
        Get a list of recipes.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        ret = []
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        runrecs = command.cooker.recipecaches[mc].runrecs
        for key, value in runrecs.items():
            if isinstance(value, defaultdict):
                value = dict(value)
            ret.append((key, value))
        return ret
    getRuntimeRecommends.readonly = True

    def getRecipeInherits(self, command, params):
        """
        Returns a list of recipes.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].inherits
    getRecipeInherits.readonly = True

    def getBbFilePriority(self, command, params):
        """
        Get bbbbbbbbbbbbbbb command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].bbfile_priority
    getBbFilePriority.readonly = True

    def getDefaultPreference(self, command, params):
        """
        Returns a list of the given command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return command.cooker.recipecaches[mc].pkg_dp
    getDefaultPreference.readonly = True

    def getSkippedRecipes(self, command, params):
        """
        Return a list of command parameters.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        # Return list sorted by reverse priority order
        import bb.cache
        skipdict = OrderedDict(sorted(command.cooker.skiplist.items(),
                                      key=lambda x: (-command.cooker.collection.calc_bbfile_priority(bb.cache.virtualfn2realfn(x[0])[0]), x[0])))
        return list(skipdict.items())
    getSkippedRecipes.readonly = True

    def getOverlayedRecipes(self, command, params):
        """
        Returns a list of command instances.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        return list(command.cooker.collection.overlayed.items())
    getOverlayedRecipes.readonly = True

    def getFileAppends(self, command, params):
        """
        Gets command parameters.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        fn = params[0]
        return command.cooker.collection.get_file_appends(fn)
    getFileAppends.readonly = True

    def getAllAppends(self, command, params):
        """
        Get all command commands.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        return command.cooker.collection.bbappends
    getAllAppends.readonly = True

    def findProviders(self, command, params):
        """
        Returns a list.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        return command.cooker.findProviders()
    findProviders.readonly = True

    def findBestProvider(self, command, params):
        """
        Finds a singleton parameters.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        (mc, pn) = split_mc_pn(params[0])
        return command.cooker.findBestProvider(pn, mc)
    findBestProvider.readonly = True

    def allProviders(self, command, params):
        """
        List all providers.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        try:
            mc = params[0]
        except IndexError:
            mc = ''
        return list(bb.providers.allProviders(command.cooker.recipecaches[mc]).items())
    allProviders.readonly = True

    def getRuntimeProviders(self, command, params):
        """
        Execute providers.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        rprovide = params[0]
        try:
            mc = params[1]
        except IndexError:
            mc = ''
        all_p = bb.providers.getRuntimeProviders(command.cooker.recipecaches[mc], rprovide)
        if all_p:
            best = bb.providers.filterProvidersRunTime(all_p, rprovide,
                            command.cooker.data,
                            command.cooker.recipecaches[mc])[0][0]
        else:
            best = None
        return all_p, best
    getRuntimeProviders.readonly = True

    def dataStoreConnectorFindVar(self, command, params):
        """
        Function to find a datastore for a given command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        name = params[1]
        datastore = command.remotedatastores[dsindex]
        value, overridedata = datastore._findVar(name)

        if value:
            content = value.get('_content', None)
            if isinstance(content, bb.data_smart.DataSmart):
                # Value is a datastore (e.g. BB_ORIGENV) - need to handle this carefully
                idx = command.remotedatastores.check_store(content, True)
                return {'_content': DataStoreConnectionHandle(idx),
                        '_connector_origtype': 'DataStoreConnectionHandle',
                        '_connector_overrides': overridedata}
            elif isinstance(content, set):
                return {'_content': list(content),
                        '_connector_origtype': 'set',
                        '_connector_overrides': overridedata}
            else:
                value['_connector_overrides'] = overridedata
        else:
            value = {}
            value['_connector_overrides'] = overridedata
        return value
    dataStoreConnectorFindVar.readonly = True

    def dataStoreConnectorGetKeys(self, command, params):
        """
        Retrieve datast datastore.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        datastore = command.remotedatastores[dsindex]
        return list(datastore.keys())
    dataStoreConnectorGetKeys.readonly = True

    def dataStoreConnectorGetVarHistory(self, command, params):
        """
        Get datast history for a given command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        name = params[1]
        datastore = command.remotedatastores[dsindex]
        return datastore.varhistory.variable(name)
    dataStoreConnectorGetVarHistory.readonly = True

    def dataStoreConnectorExpandPythonRef(self, command, params):
        """
        Evaluate a subastore command.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        config_data_dict = params[0]
        varname = params[1]
        expr = params[2]

        config_data = command.remotedatastores.receive_datastore(config_data_dict)

        varparse = bb.data_smart.VariableParse(varname, config_data)
        return varparse.python_sub(expr)

    def dataStoreConnectorRelease(self, command, params):
        """
        Sets the index of the datastore.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        if dsindex <= 0:
            raise CommandError('dataStoreConnectorRelease: invalid index %d' % dsindex)
        command.remotedatastores.release(dsindex)

    def dataStoreConnectorSetVarFlag(self, command, params):
        """
        Sets datastatastore

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        name = params[1]
        flag = params[2]
        value = params[3]
        datastore = command.remotedatastores[dsindex]
        datastore.setVarFlag(name, flag, value)

    def dataStoreConnectorDelVar(self, command, params):
        """
        Api to remove a datastore

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        name = params[1]
        datastore = command.remotedatastores[dsindex]
        if len(params) > 2:
            flag = params[2]
            datastore.delVarFlag(name, flag)
        else:
            datastore.delVar(name)

    def dataStoreConnectorRenameVar(self, command, params):
        """
        Set the datastqore name of a datastore.

        Args:
            self: (todo): write your description
            command: (str): write your description
            params: (dict): write your description
        """
        dsindex = params[0]
        name = params[1]
        newname = params[2]
        datastore = command.remotedatastores[dsindex]
        datastore.renameVar(name, newname)

    def parseRecipeFile(self, command, params):
        """
        Parse the specified recipe file (with or without bbappends)
        and return a datastore object representing the environment
        for the recipe.
        """
        fn = params[0]
        appends = params[1]
        appendlist = params[2]
        if len(params) > 3:
            config_data_dict = params[3]
            config_data = command.remotedatastores.receive_datastore(config_data_dict)
        else:
            config_data = None

        if appends:
            if appendlist is not None:
                appendfiles = appendlist
            else:
                appendfiles = command.cooker.collection.get_file_appends(fn)
        else:
            appendfiles = []
        # We are calling bb.cache locally here rather than on the server,
        # but that's OK because it doesn't actually need anything from
        # the server barring the global datastore (which we have a remote
        # version of)
        if config_data:
            # We have to use a different function here if we're passing in a datastore
            # NOTE: we took a copy above, so we don't do it here again
            envdata = bb.cache.parse_recipe(config_data, fn, appendfiles)['']
        else:
            # Use the standard path
            parser = bb.cache.NoCache(command.cooker.databuilder)
            envdata = parser.loadDataFull(fn, appendfiles)
        idx = command.remotedatastores.store(envdata)
        return DataStoreConnectionHandle(idx)
    parseRecipeFile.readonly = True

class CommandsAsync:
    """
    A class of asynchronous commands
    These functions communicate via generated events.
    Any function that requires metadata parsing should be here.
    """

    def buildFile(self, command, params):
        """
        Build a single specified .bb file
        """
        bfile = params[0]
        task = params[1]
        if len(params) > 2:
            internal = params[2]
        else:
            internal = False

        if internal:
            command.cooker.buildFileInternal(bfile, task, fireevents=False, quietlog=True)
        else:
            command.cooker.buildFile(bfile, task)
    buildFile.needcache = False

    def buildTargets(self, command, params):
        """
        Build a set of targets
        """
        pkgs_to_build = params[0]
        task = params[1]

        command.cooker.buildTargets(pkgs_to_build, task)
    buildTargets.needcache = True

    def generateDepTreeEvent(self, command, params):
        """
        Generate an event containing the dependency information
        """
        pkgs_to_build = params[0]
        task = params[1]

        command.cooker.generateDepTreeEvent(pkgs_to_build, task)
        command.finishAsyncCommand()
    generateDepTreeEvent.needcache = True

    def generateDotGraph(self, command, params):
        """
        Dump dependency information to disk as .dot files
        """
        pkgs_to_build = params[0]
        task = params[1]

        command.cooker.generateDotGraphFiles(pkgs_to_build, task)
        command.finishAsyncCommand()
    generateDotGraph.needcache = True

    def generateTargetsTree(self, command, params):
        """
        Generate a tree of buildable targets.
        If klass is provided ensure all recipes that inherit the class are
        included in the package list.
        If pkg_list provided use that list (plus any extras brought in by
        klass) rather than generating a tree for all packages.
        """
        klass = params[0]
        pkg_list = params[1]

        command.cooker.generateTargetsTree(klass, pkg_list)
        command.finishAsyncCommand()
    generateTargetsTree.needcache = True

    def findConfigFiles(self, command, params):
        """
        Find config files which provide appropriate values
        for the passed configuration variable. i.e. MACHINE
        """
        varname = params[0]

        command.cooker.findConfigFiles(varname)
        command.finishAsyncCommand()
    findConfigFiles.needcache = False

    def findFilesMatchingInDir(self, command, params):
        """
        Find implementation files matching the specified pattern
        in the requested subdirectory of a BBPATH
        """
        pattern = params[0]
        directory = params[1]

        command.cooker.findFilesMatchingInDir(pattern, directory)
        command.finishAsyncCommand()
    findFilesMatchingInDir.needcache = False

    def findConfigFilePath(self, command, params):
        """
        Find the path of the requested configuration file
        """
        configfile = params[0]

        command.cooker.findConfigFilePath(configfile)
        command.finishAsyncCommand()
    findConfigFilePath.needcache = False

    def showVersions(self, command, params):
        """
        Show the currently selected versions
        """
        command.cooker.showVersions()
        command.finishAsyncCommand()
    showVersions.needcache = True

    def showEnvironmentTarget(self, command, params):
        """
        Print the environment of a target recipe
        (needs the cache to work out which recipe to use)
        """
        pkg = params[0]

        command.cooker.showEnvironment(None, pkg)
        command.finishAsyncCommand()
    showEnvironmentTarget.needcache = True

    def showEnvironment(self, command, params):
        """
        Print the standard environment
        or if specified the environment for a specified recipe
        """
        bfile = params[0]

        command.cooker.showEnvironment(bfile)
        command.finishAsyncCommand()
    showEnvironment.needcache = False

    def parseFiles(self, command, params):
        """
        Parse the .bb files
        """
        command.cooker.updateCache()
        command.finishAsyncCommand()
    parseFiles.needcache = True

    def compareRevisions(self, command, params):
        """
        Parse the .bb files
        """
        if bb.fetch.fetcher_compare_revisions(command.cooker.data):
            command.finishAsyncCommand(code=1)
        else:
            command.finishAsyncCommand()
    compareRevisions.needcache = True

    def triggerEvent(self, command, params):
        """
        Trigger a certain event
        """
        event = params[0]
        bb.event.fire(eval(event), command.cooker.data)
        command.currentAsyncCommand = None
    triggerEvent.needcache = False

    def resetCooker(self, command, params):
        """
        Reset the cooker to its initial state, thus forcing a reparse for
        any async command that has the needcache property set to True
        """
        command.cooker.reset()
        command.finishAsyncCommand()
    resetCooker.needcache = False

    def clientComplete(self, command, params):
        """
        Do the right thing when the controlling client exits
        """
        command.cooker.clientComplete()
        command.finishAsyncCommand()
    clientComplete.needcache = False

    def findSigInfo(self, command, params):
        """
        Find signature info files via the signature generator
        """
        pn = params[0]
        taskname = params[1]
        sigs = params[2]
        res = bb.siggen.find_siginfo(pn, taskname, sigs, command.cooker.data)
        bb.event.fire(bb.event.FindSigInfoResult(res), command.cooker.data)
        command.finishAsyncCommand()
    findSigInfo.needcache = False
