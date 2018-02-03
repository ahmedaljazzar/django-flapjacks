import subprocess

from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = 'Generate, show an execution plan, and builds or ' \
           'changes the infrastructure'

    def add_arguments(self, parser):
        parser.add_argument(
            '-a', '--apply', action='store_true',
            help='Generate and show an execution plan')

    def handle(self, *args, **options):
        apply = options['apply']

        if apply:
            command = 'terraform apply'
        else:
            command = 'terraform plan'

        try:
            result = subprocess.call(command, shell=True)
        except FileNotFoundError:
            raise CommandError('terraform binary not found in PATH')

        return result
