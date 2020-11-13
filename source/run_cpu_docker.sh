docker run -it -p 8888:8888 -p 6006:6006 \
-v `pwd`/unirep/UniRep:/UniRep \
-v `pwd`/data:/data \
-v `pwd`/intermediate:/intermediate \
-v `pwd`/results:/results \
unirep-cpu:latest \
$1
