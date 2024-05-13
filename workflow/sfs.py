import os
with open("output/output_selection/selection_txt/selection_0.8887.txt", "r") as file:
    content = file.read()


lines = content.split("\n")

start_index = lines.index(" The allele frequency numbers are :-  ") + 1


end_index = next(i for i, line in enumerate(lines) if line.startswith("1. The Tajima'D for the given sequence is"))

sfs = [num for num in lines[start_index:end_index]]
sfs = " ".join(sfs)
sfs = sfs[1:len(sfs)-1]
sfs = sfs.split()
sfs = list(map(int, sfs))

print(len(sfs))
for i in sfs:
    print(i)
category = []
category[0] = sfs[0:1]
category[1] = sfs[1:2]
category[2] = sum(sfs[2:4])
category[4] = sum(sfs[4:7])
category[5] = sum(sfs[7:10])
category[6] = sum(sfs[10:20])
category[7] = sum(sfs[20:50])
category[8] = sum(sfs[50:])

for i in category:
    print(category[i])