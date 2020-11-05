"""
 AbstractSyntaxTree classes for the Bitbake language
"""

# Copyright (C) 2003, 2004 Chris Larson
# Copyright (C) 2003, 2004 Phil Blundell
# Copyright (C) 2009 Holger Hans Peter Freyther
#
# SPDX-License-Identifier: GPL-2.0-only
#

import re
import string
import logging
import bb
import itertools
from bb import methodpool
from bb.parse import logger

class StatementGroup(list):
    def eval(self, data):
        """
        Evaluate the given data.

        Args:
            self: (todo): write your description
            data: (array): write your description
        """
        for statement in self:
            statement.eval(data)

class AstNode(object):
    def __init__(self, filename, lineno):
        """
        Initialize a new filename.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
        """
        self.filename = filename
        self.lineno = lineno

class IncludeNode(AstNode):
    def __init__(self, filename, lineno, what_file, force):
        """
        Initialize a file.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            what_file: (str): write your description
            force: (bool): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.what_file = what_file
        self.force = force

    def eval(self, data):
        """
        Include the file and evaluate the statements
        """
        s = data.expand(self.what_file)
        logger.debug(2, "CONF %s:%s: including %s", self.filename, self.lineno, s)

        # TODO: Cache those includes... maybe not here though
        if self.force:
            bb.parse.ConfHandler.include(self.filename, s, self.lineno, data, "include required")
        else:
            bb.parse.ConfHandler.include(self.filename, s, self.lineno, data, False)

class ExportNode(AstNode):
    def __init__(self, filename, lineno, var):
        """
        Initialize a variable.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            var: (int): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.var = var

    def eval(self, data):
        """
        Evaluates

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        data.setVarFlag(self.var, "export", 1, op = 'exported')

class UnsetNode(AstNode):
    def __init__(self, filename, lineno, var):
        """
        Initialize a variable.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            var: (int): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.var = var

    def eval(self, data):
        """
        Evaluate the model.

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        loginfo = {
            'variable': self.var,
            'file': self.filename,
            'line': self.lineno,
        }
        data.delVar(self.var,**loginfo)

class UnsetFlagNode(AstNode):
    def __init__(self, filename, lineno, var, flag):
        """
        Initialize a new variable.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            var: (int): write your description
            flag: (int): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.var = var
        self.flag = flag

    def eval(self, data):
        """
        Evaluate variable

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        loginfo = {
            'variable': self.var,
            'file': self.filename,
            'line': self.lineno,
        }
        data.delVarFlag(self.var, self.flag, **loginfo)

class DataNode(AstNode):
    """
    Various data related updates. For the sake of sanity
    we have one class doing all this. This means that all
    this need to be re-evaluated... we might be able to do
    that faster with multiple classes.
    """
    def __init__(self, filename, lineno, groupd):
        """
        Initialize a new group.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            groupd: (list): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.groupd = groupd

    def getFunc(self, key, data):
        """
        Get a value from the value

        Args:
            self: (todo): write your description
            key: (str): write your description
            data: (todo): write your description
        """
        if 'flag' in self.groupd and self.groupd['flag'] != None:
            return data.getVarFlag(key, self.groupd['flag'], expand=False, noweakdefault=True)
        else:
            return data.getVar(key, False, noweakdefault=True, parsing=True)

    def eval(self, data):
        """
        Evaluate the data

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        groupd = self.groupd
        key = groupd["var"]
        loginfo = {
            'variable': key,
            'file': self.filename,
            'line': self.lineno,
        }
        if "exp" in groupd and groupd["exp"] != None:
            data.setVarFlag(key, "export", 1, op = 'exported', **loginfo)

        op = "set"
        if "ques" in groupd and groupd["ques"] != None:
            val = self.getFunc(key, data)
            op = "set?"
            if val == None:
                val = groupd["value"]
        elif "colon" in groupd and groupd["colon"] != None:
            e = data.createCopy()
            op = "immediate"
            val = e.expand(groupd["value"], key + "[:=]")
        elif "append" in groupd and groupd["append"] != None:
            op = "append"
            val = "%s %s" % ((self.getFunc(key, data) or ""), groupd["value"])
        elif "prepend" in groupd and groupd["prepend"] != None:
            op = "prepend"
            val = "%s %s" % (groupd["value"], (self.getFunc(key, data) or ""))
        elif "postdot" in groupd and groupd["postdot"] != None:
            op = "postdot"
            val = "%s%s" % ((self.getFunc(key, data) or ""), groupd["value"])
        elif "predot" in groupd and groupd["predot"] != None:
            op = "predot"
            val = "%s%s" % (groupd["value"], (self.getFunc(key, data) or ""))
        else:
            val = groupd["value"]

        flag = None
        if 'flag' in groupd and groupd['flag'] != None:
            flag = groupd['flag']
        elif groupd["lazyques"]:
            flag = "_defaultval"

        loginfo['op'] = op
        loginfo['detail'] = groupd["value"]

        if flag:
            data.setVarFlag(key, flag, val, **loginfo)
        else:
            data.setVar(key, val, parsing=True, **loginfo)

class MethodNode(AstNode):
    tr_tbl = str.maketrans('/.+-@%&', '_______')

    def __init__(self, filename, lineno, func_name, body, python, fakeroot):
        """
        Initialize a new function.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            func_name: (str): write your description
            body: (str): write your description
            python: (todo): write your description
            fakeroot: (str): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.func_name = func_name
        self.body = body
        self.python = python
        self.fakeroot = fakeroot

    def eval(self, data):
        """
        Evaluate a text string.

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        text = '\n'.join(self.body)
        funcname = self.func_name
        if self.func_name == "__anonymous":
            funcname = ("__anon_%s_%s" % (self.lineno, self.filename.translate(MethodNode.tr_tbl)))
            self.python = True
            text = "def %s(d):\n" % (funcname) + text
            bb.methodpool.insert_method(funcname, text, self.filename, self.lineno - len(self.body) - 1)
            anonfuncs = data.getVar('__BBANONFUNCS', False) or []
            anonfuncs.append(funcname)
            data.setVar('__BBANONFUNCS', anonfuncs)
        if data.getVar(funcname, False):
            # clean up old version of this piece of metadata, as its
            # flags could cause problems
            data.delVarFlag(funcname, 'python')
            data.delVarFlag(funcname, 'fakeroot')
        if self.python:
            data.setVarFlag(funcname, "python", "1")
        if self.fakeroot:
            data.setVarFlag(funcname, "fakeroot", "1")
        data.setVarFlag(funcname, "func", 1)
        data.setVar(funcname, text, parsing=True)
        data.setVarFlag(funcname, 'filename', self.filename)
        data.setVarFlag(funcname, 'lineno', str(self.lineno - len(self.body)))

class PythonMethodNode(AstNode):
    def __init__(self, filename, lineno, function, modulename, body):
        """
        Initialize a function.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            function: (callable): write your description
            modulename: (str): write your description
            body: (str): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.function = function
        self.modulename = modulename
        self.body = body

    def eval(self, data):
        """
        Evaluate the text document

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        # Note we will add root to parsedmethods after having parse
        # 'this' file. This means we will not parse methods from
        # bb classes twice
        text = '\n'.join(self.body)
        bb.methodpool.insert_method(self.modulename, text, self.filename, self.lineno - len(self.body) - 1)
        data.setVarFlag(self.function, "func", 1)
        data.setVarFlag(self.function, "python", 1)
        data.setVar(self.function, text, parsing=True)
        data.setVarFlag(self.function, 'filename', self.filename)
        data.setVarFlag(self.function, 'lineno', str(self.lineno - len(self.body) - 1))

class ExportFuncsNode(AstNode):
    def __init__(self, filename, lineno, fns, classname):
        """
        Initialize a classname.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            fns: (str): write your description
            classname: (str): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.n = fns.split()
        self.classname = classname

    def eval(self, data):
        """
        Evaluate the data.

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """

        for func in self.n:
            calledfunc = self.classname + "_" + func

            if data.getVar(func, False) and not data.getVarFlag(func, 'export_func', False):
                continue

            if data.getVar(func, False):
                data.setVarFlag(func, 'python', None)
                data.setVarFlag(func, 'func', None)

            for flag in [ "func", "python" ]:
                if data.getVarFlag(calledfunc, flag, False):
                    data.setVarFlag(func, flag, data.getVarFlag(calledfunc, flag, False))
            for flag in [ "dirs" ]:
                if data.getVarFlag(func, flag, False):
                    data.setVarFlag(calledfunc, flag, data.getVarFlag(func, flag, False))
            data.setVarFlag(func, "filename", "autogenerated")
            data.setVarFlag(func, "lineno", 1)

            if data.getVarFlag(calledfunc, "python", False):
                data.setVar(func, "    bb.build.exec_func('" + calledfunc + "', d)\n", parsing=True)
            else:
                if "-" in self.classname:
                   bb.fatal("The classname %s contains a dash character and is calling an sh function %s using EXPORT_FUNCTIONS. Since a dash is illegal in sh function names, this cannot work, please rename the class or don't use EXPORT_FUNCTIONS." % (self.classname, calledfunc))
                data.setVar(func, "    " + calledfunc + "\n", parsing=True)
            data.setVarFlag(func, 'export_func', '1')

class AddTaskNode(AstNode):
    def __init__(self, filename, lineno, func, before, after):
        """
        Initialize a new function.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            func: (callable): write your description
            before: (todo): write your description
            after: (todo): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.func = func
        self.before = before
        self.after = after

    def eval(self, data):
        """
        Evaluate task.

        Args:
            self: (todo): write your description
            data: (array): write your description
        """
        bb.build.addtask(self.func, self.before, self.after, data)

class DelTaskNode(AstNode):
    def __init__(self, filename, lineno, func):
        """
        Initialize a function.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            func: (callable): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.func = func

    def eval(self, data):
        """
        Evaluate the given data.

        Args:
            self: (todo): write your description
            data: (array): write your description
        """
        bb.build.deltask(self.func, data)

class BBHandlerNode(AstNode):
    def __init__(self, filename, lineno, fns):
        """
        Initialize a file.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            fns: (str): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.hs = fns.split()

    def eval(self, data):
        """
        Evaluate the hyperlog.

        Args:
            self: (todo): write your description
            data: (todo): write your description
        """
        bbhands = data.getVar('__BBHANDLERS', False) or []
        for h in self.hs:
            bbhands.append(h)
            data.setVarFlag(h, "handler", 1)
        data.setVar('__BBHANDLERS', bbhands)

class InheritNode(AstNode):
    def __init__(self, filename, lineno, classes):
        """
        Initialize the classes.

        Args:
            self: (todo): write your description
            filename: (str): write your description
            lineno: (int): write your description
            classes: (todo): write your description
        """
        AstNode.__init__(self, filename, lineno)
        self.classes = classes

    def eval(self, data):
        """
        Evaluates.

        Args:
            self: (todo): write your description
            data: (array): write your description
        """
        bb.parse.BBHandler.inherit(self.classes, self.filename, self.lineno, data)

def handleInclude(statements, filename, lineno, m, force):
    """
    Handles statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        m: (todo): write your description
        force: (bool): write your description
    """
    statements.append(IncludeNode(filename, lineno, m.group(1), force))

def handleExport(statements, filename, lineno, m):
    """
    Handles statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        m: (todo): write your description
    """
    statements.append(ExportNode(filename, lineno, m.group(1)))

def handleUnset(statements, filename, lineno, m):
    """
    Handle statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (todo): write your description
        m: (todo): write your description
    """
    statements.append(UnsetNode(filename, lineno, m.group(1)))

def handleUnsetFlag(statements, filename, lineno, m):
    """
    Handle statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (todo): write your description
        m: (todo): write your description
    """
    statements.append(UnsetFlagNode(filename, lineno, m.group(1), m.group(2)))

def handleData(statements, filename, lineno, groupd):
    """
    Handle statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        groupd: (todo): write your description
    """
    statements.append(DataNode(filename, lineno, groupd))

def handleMethod(statements, filename, lineno, func_name, body, python, fakeroot):
    """
    Handle statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        func_name: (str): write your description
        body: (todo): write your description
        python: (todo): write your description
        fakeroot: (todo): write your description
    """
    statements.append(MethodNode(filename, lineno, func_name, body, python, fakeroot))

def handlePythonMethod(statements, filename, lineno, funcname, modulename, body):
    """
    Handle statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (todo): write your description
        funcname: (str): write your description
        modulename: (str): write your description
        body: (todo): write your description
    """
    statements.append(PythonMethodNode(filename, lineno, funcname, modulename, body))

def handleExportFuncs(statements, filename, lineno, m, classname):
    """
    Process statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        m: (todo): write your description
        classname: (str): write your description
    """
    statements.append(ExportFuncsNode(filename, lineno, m.group(1), classname))

def handleAddTask(statements, filename, lineno, m):
    """
    Add statements.

    Args:
        statements: (todo): write your description
        filename: (str): write your description
        lineno: (str): write your description
        m: (todo): write your description
    """
    func = m.group("func")
    before = m.group("before")
    after = m.group("after")
    if func is None:
        return

    statements.append(AddTaskNode(filename, lineno, func, before, after))

def handleDelTask(statements, filename, lineno, m):
    """
    Handle statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        m: (todo): write your description
    """
    func = m.group("func")
    if func is None:
        return

    statements.append(DelTaskNode(filename, lineno, func))

def handleBBHandlers(statements, filename, lineno, m):
    """
    Handle handlers.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (str): write your description
        m: (todo): write your description
    """
    statements.append(BBHandlerNode(filename, lineno, m.group(1)))

def handleInherit(statements, filename, lineno, m):
    """
    Handles statements.

    Args:
        statements: (list): write your description
        filename: (str): write your description
        lineno: (todo): write your description
        m: (todo): write your description
    """
    classes = m.group(1)
    statements.append(InheritNode(filename, lineno, classes))

def runAnonFuncs(d):
    """
    Run all functions in the given dictionary.

    Args:
        d: (todo): write your description
    """
    code = []
    for funcname in d.getVar("__BBANONFUNCS", False) or []:
        code.append("%s(d)" % funcname)
    bb.utils.better_exec("\n".join(code), {"d": d})

def finalize(fn, d, variant = None):
    """
    Finalize the event handlers.

    Args:
        fn: (todo): write your description
        d: (todo): write your description
        variant: (todo): write your description
    """
    saved_handlers = bb.event.get_handlers().copy()
    try:
        for var in d.getVar('__BBHANDLERS', False) or []:
            # try to add the handler
            handlerfn = d.getVarFlag(var, "filename", False)
            if not handlerfn:
                bb.fatal("Undefined event handler function '%s'" % var)
            handlerln = int(d.getVarFlag(var, "lineno", False))
            bb.event.register(var, d.getVar(var, False), (d.getVarFlag(var, "eventmask") or "").split(), handlerfn, handlerln)

        bb.event.fire(bb.event.RecipePreFinalise(fn), d)

        bb.data.expandKeys(d)
        runAnonFuncs(d)

        tasklist = d.getVar('__BBTASKS', False) or []
        bb.event.fire(bb.event.RecipeTaskPreProcess(fn, list(tasklist)), d)
        bb.build.add_tasks(tasklist, d)

        bb.parse.siggen.finalise(fn, d, variant)

        d.setVar('BBINCLUDED', bb.parse.get_file_depends(d))

        bb.event.fire(bb.event.RecipeParsed(fn), d)
    finally:
        bb.event.set_handlers(saved_handlers)

def _create_variants(datastores, names, function, onlyfinalise):
    """
    Create a set of variants.

    Args:
        datastores: (todo): write your description
        names: (str): write your description
        function: (todo): write your description
        onlyfinalise: (str): write your description
    """
    def create_variant(name, orig_d, arg = None):
        """
        Creates a variant.

        Args:
            name: (str): write your description
            orig_d: (str): write your description
            arg: (str): write your description
        """
        if onlyfinalise and name not in onlyfinalise:
            return
        new_d = bb.data.createCopy(orig_d)
        function(arg or name, new_d)
        datastores[name] = new_d

    for variant in list(datastores.keys()):
        for name in names:
            if not variant:
                # Based on main recipe
                create_variant(name, datastores[""])
            else:
                create_variant("%s-%s" % (variant, name), datastores[variant], name)

def multi_finalize(fn, d):
    """
    Finalize multiple files.

    Args:
        fn: (todo): write your description
        d: (todo): write your description
    """
    appends = (d.getVar("__BBAPPEND") or "").split()
    for append in appends:
        logger.debug(1, "Appending .bbappend file %s to %s", append, fn)
        bb.parse.BBHandler.handle(append, d, True)

    onlyfinalise = d.getVar("__ONLYFINALISE", False)

    safe_d = d
    d = bb.data.createCopy(safe_d)
    try:
        finalize(fn, d)
    except bb.parse.SkipRecipe as e:
        d.setVar("__SKIPPED", e.args[0])
    datastores = {"": safe_d}

    extended = d.getVar("BBCLASSEXTEND") or ""
    if extended:
        # the following is to support bbextends with arguments, for e.g. multilib
        # an example is as follows:
        #   BBCLASSEXTEND = "multilib:lib32"
        # it will create foo-lib32, inheriting multilib.bbclass and set
        # BBEXTENDCURR to "multilib" and BBEXTENDVARIANT to "lib32"
        extendedmap = {}
        variantmap = {}

        for ext in extended.split():
            eext = ext.split(':', 2)
            if len(eext) > 1:
                extendedmap[ext] = eext[0]
                variantmap[ext] = eext[1]
            else:
                extendedmap[ext] = ext

        pn = d.getVar("PN")
        def extendfunc(name, d):
            """
            Extend a function to a file

            Args:
                name: (str): write your description
                d: (todo): write your description
            """
            if name != extendedmap[name]:
                d.setVar("BBEXTENDCURR", extendedmap[name])
                d.setVar("BBEXTENDVARIANT", variantmap[name])
            else:
                d.setVar("PN", "%s-%s" % (pn, name))
            bb.parse.BBHandler.inherit(extendedmap[name], fn, 0, d)

        safe_d.setVar("BBCLASSEXTEND", extended)
        _create_variants(datastores, extendedmap.keys(), extendfunc, onlyfinalise)

    for variant in datastores.keys():
        if variant:
            try:
                if not onlyfinalise or variant in onlyfinalise:
                    finalize(fn, datastores[variant], variant)
            except bb.parse.SkipRecipe as e:
                datastores[variant].setVar("__SKIPPED", e.args[0])

    datastores[""] = d
    return datastores
