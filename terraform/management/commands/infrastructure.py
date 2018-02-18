import os
import subprocess
import sys
import uuid
import zipfile

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from git import Repo


class Command(BaseCommand):
    help = 'Generate, show an execution plan, and builds or ' \
           'changes the infrastructure'

    def __init__(self, **kwargs):
        super(Command, self).__init__(**kwargs)
        self.lambda_file_name = '{}.zip'.format(str(uuid.uuid4()))

    def add_arguments(self, parser):
        parser.add_argument(
            '-a', '--apply', action='store_true',
            help='Generate and show an execution plan')

    def handle(self, *args, **options):
        apply = options['apply']

        self.update_terraform_settings()
        if apply:
            command = self.generate_terraform_apply()
        else:
            command = self.generate_terraform_plan()

        self.zip_the_package()

        try:
            subprocess.call(command, shell=True)
        except FileNotFoundError:
            raise CommandError('Terraform binary not found in PATH')
        finally:
            self.delete_packaged_file()

    def generate_terraform_plan(self):
        self.stdout.write('Running Terraform Plan job...')
        return 'terraform plan'

    def generate_terraform_apply(self):
        self.stdout.write('Running Terraform Apply job...')
        if settings.DEBUG:
            self.stderr.write(
                'Cannot deploy a debug mode to Lambda. Consider '
                'choosing a proper settings file.')
            sys.exit(0)

        return 'terraform apply'

    def update_terraform_settings(self):
        self.stdout.write('Preparing Terraform env file...')
        tf_file = open(settings.TERRAFORM_VARS_FILE, 'w')

        self.stdout.write('Fetching project settings and reflect them '
                          'on Terraform env file...')

        for key in settings._explicit_settings:
            value = getattr(settings, key)
            line = 'variable "%s" { default = "%s" }\n' % (key, value)
            tf_file.write(line)


        lambda_key = os.path.join(
            settings.LAMBDA_FUNCTION_LOCATION,
            self.lambda_file_name
        )
        lambda_env = '''
        variable "LAMBDA_FILE_KEY" { default = "%s" }\n       
        variable "LAMBDA_FILE_NAME" { default = "%s" }\n
        ''' % (lambda_key, self.lambda_file_name)

        tf_file.write(lambda_env)

        tf_file.close()
        self.stdout.write('Terraform ENVs collected successfully',
                          style_func=self.style.SUCCESS)

    def zip_the_package(self):
        libs = sys.executable.replace(
            'bin/python', 'lib/python3.6/site-packages',)
        paths = (
            libs,
            settings.BASE_DIR,
        )
        repo = Repo(settings.BASE_DIR)

        if repo.is_dirty():
            self.stderr.write(
                'You are trying to publish a new version while your '
                'project is not clean.')

            self.stdout.write('HINT: Commit your changes or remove the'
                              ' publish flag from the command.')
            sys.exit(0)

        self.stdout.write('Packaging the project...')
        with zipfile.ZipFile(self.lambda_file_name, 'w',
                             zipfile.ZIP_DEFLATED) as archive:
            for path in paths:
                for full_path, archive_name in self._files_to_zip(path):
                    st = os.stat(full_path)
                    # Readable for everybody
                    os.chmod(full_path, st.st_mode | 0o0444)
                    archive.write(full_path, archive_name)

        self.stdout.write(
            'The project packaged successfully',
            style_func=self.style.SUCCESS)

    def delete_packaged_file(self):
        if os.path.exists(self.lambda_file_name):
            self.stdout.write('Removing the packaged file...')
            os.remove(self.lambda_file_name)
            self.stdout.write('The packaged file removed successfully',
                              style_func=self.style.SUCCESS)

    @staticmethod
    def allowed_to_package(file, root):
        good_ext = not file.endswith('pyc') and not file.endswith('zip')
        good_root = (
                not '.terraform' in root and
                not '.git' in root and
                not '.egg-info' in root and
                not 'dist' in root
        )
        return good_ext and good_root

    def _files_to_zip(self, path):
        """
        Fetches all valid files in the path except the `.pyc` ones
        :param path: The root path of the files we wanna archive
        :return: - A list of files and names ready for compressing
                 - Nothing if the path is not a dir
        """
        if not os.path.isdir(path):
            self.stderr.write(
                'Cannot archive "%s" as it is not a directory!' % path)
            return

        for root, dirs, files in os.walk(path):
            for f in files:
                if self.allowed_to_package(f, root):
                    full_path = os.path.join(root, f)
                    archive_name = full_path[len(path) + len(os.sep):]

                    yield full_path, archive_name
