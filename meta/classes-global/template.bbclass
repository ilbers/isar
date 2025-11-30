# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

TEMPLATE_FILES ?= ""
TEMPLATE_VARS ?= "BPN PN PV DESCRIPTION HOMEPAGE MAINTAINER DISTRO_ARCH"

do_transform_template[vardeps] = "TEMPLATE_FILES ${TEMPLATE_VARS}"
python do_transform_template() {
    import subprocess, contextlib, shutil

    workdir = os.path.normpath(d.getVar('WORKDIR'))

    template_vars = (d.getVar('TEMPLATE_VARS') or "").split()
    if len(template_vars) == 0:
        return

    template_files = (d.getVar('TEMPLATE_FILES') or "").split()
    if len(template_files) == 0:
        return

    cmd = "envsubst"
    args = " ".join(r"\${{{}}}".format(i) for i in template_vars)

    # Copy current process environment and add template variables
    # from bitbake data store:
    env = os.environ.copy()
    for varname in template_vars:
        value = d.getVar(varname)
        if value:
            env.update({varname: value})

    for template_file in template_files:
        # Normpath and workdir checks should prevent accidential or
        # uninformed changes to files outside of the tmp and workdirectoy
        template_file = os.path.normpath(template_file)

        # Convert relative paths to absolut paths based on the workdir:
        if not os.path.isabs(template_file):
            template_file = os.path.normpath(os.path.join(workdir, template_file))

        if not template_file.startswith(workdir):
            bb.fatal("Template file ({}) is not within workdir ({})"
                     .format(template_file, workdir))

        output_file = (os.path.splitext(template_file)[0]
                       if template_file.endswith(".tmpl")
                       else (template_file + ".out"))
        bb.note("{} {} [in: {} out: {}]".format(cmd, args,
                                                template_file, output_file))
        with contextlib.ExitStack() as stack:
            input = stack.enter_context(open(template_file, 'rb'))
            output = stack.enter_context(open(output_file, 'wb'))
            process = stack.enter_context(subprocess.Popen([cmd, args], stdin=input,
                                          stdout=output, env=env))
            if process.wait() != 0:
                bb.fatal("processing of template failed")

        shutil.copymode(template_file, output_file)
}
addtask do_transform_template after do_unpack
