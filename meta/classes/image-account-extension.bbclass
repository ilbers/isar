# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019-2023
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass for creating user accounts and groups.

USERS ??= ""

#USERS += "root"
#USER_root[password] = "" # Encrypted password, or clear-text when [flags] = "clear-text-password"
#USER_root[expire] = ""
#USER_root[inactive] = ""
#USER_root[uid] = ""
#USER_root[gid] = "" # If first character is a number: gid, otherwise groupname
#USER_root[comment] = "The ultimate root user"
#USER_root[home] = "/home/root"
#USER_root[shell] = "/bin/sh"
#USER_root[groups] = "audio video"
#USER_root[flags] = "no-create-home create-home system allow-empty-password clear-text-password force-passwd-change"

GROUPS ??= ""

#GROUPS += "root"
#GROUP_root[gid] = ""
#GROUP_root[flags] = "system"


def image_create_groups(d: "DataSmart") -> None:
    """Creates the groups defined in the ``GROUPS`` bitbake variable.

    Args:
        d (DataSmart): The bitbake datastore.

    Returns:
        None
    """
    entries = (d.getVar("GROUPS") or "").split()
    rootfsdir = d.getVar("ROOTFSDIR")
    chroot = ["sudo", "-E", "chroot", rootfsdir]

    for entry in entries:
        args = []
        group_entry = "GROUP_{}".format(entry)

        with open("{}/etc/group".format(rootfsdir), "r") as group_file:
            exists = any(line.startswith("{}:".format(entry)) for line in group_file)

        gid = d.getVarFlag(group_entry, "gid") or ""
        if gid:
            args.append("--gid")
            args.append(gid)

        if exists:
            if args:
                bb.process.run([*chroot, "/usr/sbin/groupmod", *args, entry])
        else:
            flags = (d.getVarFlag(group_entry, "flags") or "").split()
            if "system" in flags:
                args.append("--system")

            bb.process.run([*chroot, "/usr/sbin/groupadd", *args, entry])


def image_create_users(d: "DataSmart") -> None:
    """Creates the users defined in the ``USERS`` bitbake variable.

    Args:
        d (DataSmart): The bitbake datastore.

    Returns:
        None
    """
    import hashlib
    import crypt

    entries = (d.getVar("USERS") or "").split()
    rootfsdir = d.getVar("ROOTFSDIR")
    chroot = ["sudo", "-E", "chroot", rootfsdir]

    for entry in entries:
        args = []
        user_entry = "USER_{}".format(entry)

        with open("{}/etc/passwd".format(rootfsdir), "r") as passwd_file:
            exists = any(line.startswith("{}:".format(entry)) for line in passwd_file)

        def add_user_option(option_name, flag_name):
            flag_value = d.getVarFlag(user_entry, flag_name) or ""
            if flag_value:
                args.append(option_name)
                args.append(flag_value)

        add_user_option("--expire", "expiredate")
        add_user_option("--inactive", "inactive")
        add_user_option("--uid", "uid")
        add_user_option("--gid", "gid")
        add_user_option("--comment", "comment")
        add_user_option("--shell", "shell")

        groups = d.getVarFlag(user_entry, "groups") or ""
        if groups:
            args.append("--groups")
            args.append(groups.replace(' ', ','))

        flags = (d.getVarFlag(user_entry, "flags") or "").split()

        if exists:
            add_user_option("--home", "home")
            if d.getVarFlag(user_entry, "home") or "":
                args.append("--move-home")
        else:
            add_user_option("--home-dir", "home")

            if "system" in flags:
                args.append("--system")
            if "no-create-home" in flags:
                args.append("--no-create-home")
            if "create-home" in flags:
                args.append("--create-home")

        if exists:
            if args:
                bb.process.run([*chroot, "/usr/sbin/usermod", *args, entry])
        else:
            bb.process.run([*chroot, "/usr/sbin/useradd", *args, entry])

        command = [*chroot, "/usr/sbin/chpasswd"]
        password = d.getVarFlag(user_entry, "password") or ""
        if password or "allow-empty-password" in flags:
            if "clear-text-password" in flags:

                # chpasswd adds a random salt when running against a clear-text password.
                # For reproducible images, we manually generate the password and use the
                # SOURCE_DATE_EPOCH to generate the salt in a deterministic way.
                source_date_epoch = d.getVar("SOURCE_DATE_EPOCH") or ""
                if source_date_epoch:
                    command.append("-e")
                    salt = hashlib.sha256("{}\n".format(source_date_epoch).encode()).hexdigest()[0:15]
                    password = crypt.crypt(password, "$6${}".format(salt))

            else:
                command.append("-e")

            bb.process.run(command, "{}:{}".format(entry, password).encode())

        if "force-passwd-change" in flags:
            bb.process.run([*chroot, "/usr/sbin/passwd", "--expire", entry])


ROOTFS_POSTPROCESS_COMMAND += "image_postprocess_accounts"
python image_postprocess_accounts() {
    image_create_groups(d)
    image_create_users(d)
}
