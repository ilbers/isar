# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

python() {
    additional_packages = d.getVar('TARGET_BOOTSTRAPPER_ADDITIONAL_PACKAGES').split()

    names    = []
    workdirs = []
    scripts  = []
    efforts  = []
    effort_total = 0

    for package in additional_packages:
        additional_package_task = f"TARGET_BOOTSTRAPPER_TASK_{package}"

        names.append(package)
        workdirs.append(d.getVarFlag(additional_package_task, "workdir") or ".")

        script = d.getVarFlag(additional_package_task, "script")
        if not script:
            bb.warn("Script not set for {task_name} - consider setting {task_name}[script] = \"<your-script-for-{task_name}>\"".format(task_name=additional_package_task))

        scripts.append(script or "/bin/true")

        effort = d.getVarFlag(additional_package_task, "effort") or "1"
        efforts.append(effort)

        effort_total = effort_total + int(effort)

    d.setVar('TMPL_TARGET_BOOTSTRAPPER_TASK_NAMES', ' '.join(names))
    d.setVar('TMPL_TARGET_BOOTSTRAPPER_TASK_WORKDIRS', ' '.join(workdirs))
    d.setVar('TMPL_TARGET_BOOTSTRAPPER_TASK_SCRIPTS', ' '.join(scripts))
    d.setVar('TMPL_TARGET_BOOTSTRAPPER_TASK_EFFORTS', ' '.join(efforts))
    d.setVar('TMPL_TARGET_BOOTSTRAPPER_TASK_TOTAL_EFFORT', str(effort_total))
}
