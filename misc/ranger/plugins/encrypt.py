import os
import tarfile
from gnupg import GPG
from ranger.api.commands import Command
from subprocess import run


class encrypt(Command):
    """:encrypt

    Encrypts a file or dir (as a tar.gz) with the default gpg key
    """

    def tardir(self, path):
        """:tardir

        tars a directory into a dir of the same name appended with .tar.gz

        returns the name of the tarfile
        """
        output_path = path + '.tar.gz'

        with tarfile.open(output_path, "w:gz") as tar_handle:
            for root, dirs, files in os.walk(path):
                for file in files:
                    tar_handle.add(os.path.join(root, file))

        return output_path

    def execute(self):
        gpg_home = os.path.join(os.path.expanduser('~'), '.gnupg/')
        default_recpipient = os.environ['DEFAULT_RECIPIENT']

        if not default_recpipient:
            self.fm.notify('DEFAULT_RECIPIENT environment variable must be set')
            return

        gpg = GPG(gpgbinary='/usr/bin/gpg', gnupghome=gpg_home)

        paths = [os.path.basename(f.path) for f in self.fm.thistab.get_selection()]

        for p in paths:
            if os.path.isdir(p):
                new_p = self.tardir(p)
                run(['rm', '-rf', p])
                p = new_p

            with open(p, 'rb') as f:
                enc = gpg.encrypt_file(f, default_recpipient)

            with open(p + '.gpg', 'wb+') as out:
                out.write(enc.data)

            if os.path.isfile(p):
                os.remove(p)
