import os
import time
from novaclient import client
import novaclient.exceptions
from credentials import get_nova_creds
import ConfigParser

SSH_PUBKEY = '/var/lib/jenkins/.ssh/id_rsa.pub'


class CloudSlave:
    def __init__(self, name):
        # read the config
        config = ConfigParser.ConfigParser()
        config.read(os.path.join(
            os.path.dirname(os.path.realpath(__file__)), 'config.ini'))

        self.name = name
        self.imagename = config.get('openstack', 'imagename')
        self.flavorname = config.get('openstack', 'flavor')
        self.sshkeyname = config.get('openstack', 'sshkeyname')
        self.netid = config.get('openstack', 'netid')

    def spinup(self):
        # initialise novaclient instance
        creds = get_nova_creds()
        nova = client.Client('2', **creds)

        # ensure jenkins' pubkey is loaded
        if not nova.keypairs.findall(name=self.sshkeyname):
            with open(os.path.expanduser(SSH_PUBKEY)) as fpubkey:
                nova.keypairs.create(
                    name=self.sshkeyname, public_key=fpubkey.read())

        image = nova.images.find(name=self.imagename)
        if not image:
            raise Exception('Could not find image...')

        flavor = nova.flavors.find(name=self.flavorname)
        if not flavor:
            raise Exception('Could not find flavor...')

        # Get a floating IP early to fail faster if we are over quota
        floating_ip = nova.floating_ips.create()

        # spin up a cloud instance!!
        # TODO: figure out how to determine net-id
        self.instance = nova.servers.create(
            name=self.name,
            image=image,
            flavor=flavor,
            key_name=self.sshkeyname,
            nics=[{'net-id': self.netid}])

        # Poll at 5 second intervals, until the status is no longer 'BUILD'
        status = self.instance.status
        while status == 'BUILD':
            print('Building minion %s' % self.name)
            time.sleep(5)
            # Retrieve the instance again so the status field updates
            self.instance = nova.servers.get(self.instance.id)
            status = self.instance.status

        # assign floating ip
        try:
            self.instance.add_floating_ip(floating_ip)
            self.ip = floating_ip.ip
        except:
            self.instance.delete()
            raise

        return self.ip

    def spindown(self):
        creds = get_nova_creds()
        nova = client.Client('2', **creds)

        maxtries = 10
        trycount = 0
        while 1:
            try:
                instance = nova.servers.find(name=self.name)
                # Release/delete the associated floating IP first
                try:
                    floating_ip = nova.floating_ips.find(
                        instance_id=instance.id)
                    floating_ip.delete()
                except novaclient.exceptions.NotFound:
                    # No floating IP assigned, it's alright
                    pass
                # Then delete the instance
                instance.delete()
                return True
            except novaclient.exceptions.NotFound:
                # Instance does not exist, nothing to do
                return False
            except Exception as e:
                print('Problem retrieving/deleting server instance...')
                print(str(e))

                if trycount > maxtries:
                    raise

                print('Retrying in 10s...')
                time.sleep(10)  # wait a bit and try again
                trycount += 1
