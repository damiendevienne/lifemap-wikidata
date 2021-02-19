import re
import sys
f = open(sys.argv[1], "r")
flag=0
for x in f:
  # print(x)
  regex = re.compile("\"[^\"]*\"")
  resultat = regex.findall(x)
  if len(resultat) > 1 :
      if resultat[0] == "\"taxid\"" :
          # print(resultat[0]+"====>"+resultat[1])
          # buf = resultat[1].split(" | ")
          # species=buf[0][1:]
          taxid=resultat[1][1:-1]
          # print("taxid="+taxid)
          flag=1
      if resultat[0] == "\"sci_name\"" :
          # print(resultat[0]+"====>"+resultat[1])
          # buf = resultat[1].split(" | ")
          # species=buf[0][1:]
          sci_name=resultat[1][1:-1]
          # print("sci_name="+sci_name)
          if flag == 1:
              print(taxid+"\t"+sci_name)
              flag=0
          else:
              # print("erreur: "+x,file=sys.stderr)
              sys.stderr.write("error at ligne "+x)
              exit(1)
          #   else:
          #      priint("erreur ligne "+x)
          #      exit(1)
