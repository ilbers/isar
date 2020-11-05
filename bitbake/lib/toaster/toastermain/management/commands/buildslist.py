#
# SPDX-License-Identifier: GPL-2.0-only
#

from django.core.management.base import BaseCommand, CommandError
from orm.models import Build
import os



class Command(BaseCommand):
    args    = ""
    help    = "Lists current builds"

    def handle(self,**options):
        """
        Executes all permissions.

        Args:
            self: (todo): write your description
            options: (todo): write your description
        """
        for b in Build.objects.all():
            print("%d: %s %s %s" % (b.pk, b.machine, b.distro, ",".join([x.target for x in b.target_set.all()])))
