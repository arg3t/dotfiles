import os
import tarfile
from gnupg import GPG
from ranger.api.commands import Command


class decrypt(Command):
    """:decrypts

    Decrypts a file with gpg or a directory by extracting a tar file and decrypting it

    passing true as the false flag will not delete the origin gpg file
    """

    def execute(self):
        gpg = GPG(gnupghome=os.path.join(os.path.expanduser('~'), '.gnupg'))

        paths = [os.path.basename(f.path) for f in self.fm.thistab.get_selection()]

        for p in [p for p in paths if p.endswith('gpg')]:
            with open(p, 'rb') as enc:
                dec_b = gpg.decrypt_file(enc)

            out_fname = os.path.splitext(p)[0]
            with open(out_fname, 'wb+') as dec_f:
                dec_f.write(dec_b.data)

            if self.arg(1) != 'true':
                os.remove(p)

            if tarfile.is_tarfile(out_fname):
                tarfile.open(out_fname).extractall(path='.')
                os.remove(out_fname)
