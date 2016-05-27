import sys
import time
from openstack import CloudSlave

if __name__ == "__main__":
    instancename = sys.argv[1]  # use argparse to be proper :D

    minion = CloudSlave(instancename)
    if minion.spindown():
        print("Cloud instance %s deleted" % instancename)
        time.sleep(25)  # ensure all resources have been released
    else:
        print("No cloud instance to delete ;)")
