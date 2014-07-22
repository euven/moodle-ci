import sys
import time
from jenkins_cloud import cloudslave

if __name__ == "__main__":
    instancename = sys.argv[1]  # use argparse to be proper :D

    minion = cloudslave(instancename)
    if minion.spindown():
        print "Cloud instance %s deleted" % instancename
	time.sleep(15)  # ensure all resources have been released
    else:
        print "No cloud instance to delete ;)"
