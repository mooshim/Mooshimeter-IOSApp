import os

# list of target sizes, (pixels, (scales))
sizes = [(29,(1,2,3)), (40,(2,3)), (57,(1,2)), (60,(2,3)), (29,(1,2)), (40,(1,2)), (50,(1,2)), (72,(1,2)), (76,(1,2))]

fin  = "icon.png"
fout_format = "icon-%d_%d.png"

for pix, scales in sizes:
	for s in scales:
		fout = fout_format%(pix,s)
		res = s*pix
		os.system("rm %s"%fout)
		os.system("cp -v %s %s"%(fin,fout))
		os.system("sips -Z %d %s"%(res,fout))

print "Done"
