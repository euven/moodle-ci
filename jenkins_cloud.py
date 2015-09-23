import os
import time
import novaclient.v1_1.client as nvclient
import novaclient.exceptions
from credentials import get_nova_creds

class cloudslave:
    def __init__(self, name):
        self.name = name
        self.imagename = "jenkinstest"
        self.flavorname = "c1.c4r4"
        #self.flavorname = "c1.c8r8"
        self.sshkeyname = "jenkins"

    def spinup(self):
        # initialise novaclient instance
        creds = get_nova_creds()
        nova = nvclient.Client(**creds)

        # ensure jenkins' pubkey is loaded
        if not nova.keypairs.findall(name="jenkins"):
            with open(os.path.expanduser('/var/lib/jenkins/.ssh/id_rsa.pub')) as fpubkey:
                nova.keypairs.create(name=self.sshkeyname, public_key=fpubkey.read())

        image = nova.images.find(name=self.imagename)
        if not image:
            raise Exception('Could not find image...')

        flavor = nova.flavors.find(name=self.flavorname)
        if not flavor:
            raise Exception('Could not find flavor...')

        # spin up a cloud instance!!
        self.instance = nova.servers.create(name=self.name, image=image, flavor=flavor, key_name="jenkins", nics=[{'net-id':'eadc7a9b-2ced-4b75-9915-552e6d09da3f'}])  #TODO: figure out how to determine net-id

        # Poll at 5 second intervals, until the status is no longer 'BUILD'
        status = self.instance.status
        while status == 'BUILD':
            print 'Building minion %s' % self.name
            time.sleep(5)
            # Retrieve the instance again so the status field updates
            self.instance = nova.servers.get(self.instance.id)
            status = self.instance.status

        # assign floating ip
        floating_ips = nova.floating_ips.list()
        if not floating_ips:
            self.instance.delete()
            raise Exception('No floating ips in pool :(') # todo: try creating some?
	for fip in floating_ips:
            if fip.instance_id is None:  # not assigned to another instance
                self.ip = fip.ip
        	self.instance.add_floating_ip(self.ip)
                break
        try:
            self.ip
        except:
            self.instance.delete()
            raise Exception('No available floating ips :(') # todo: try creating some?

        #time.sleep(10) # sleep a bit, while the floating ip gets sorted

        return self.ip

    def spindown(self):
        creds = get_nova_creds()
        nova = nvclient.Client(**creds)

	maxtries = 10
	trycount = 0
	while 1:
            try:
	        instance = nova.servers.find(name=self.name)
                if instance:
                    instance.delete()
                    return True
                else:
                    return False
            except novaclient.exceptions.ClientException:
                print 'Problem retrieving server instance...'
                if trycount > maxtries:
                    return False

                print 'retrying...'
                time.sleep(5)  # wait a bit and try again
                trycount = trycount + 1
                continue
