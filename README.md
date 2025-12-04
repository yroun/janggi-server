
```commandline
curl -L -o fairy_xq.zip https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14_0_1_xq.zip
unzip fairy_xq.zip
cd Fairy-Stockfish-fairy_sf_14_0_1_xq/src

# 1. 샹치(중국장기)용 NNUE 다운로드
curl -L -O https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/xiangqi-83f16c17fe26.nnue
# 2. 장기(한국장기)용 NNUE 다운로드 (가장 중요!)
curl -L -O https://github.com/fairy-stockfish/Fairy-Stockfish/releases/download/fairy_sf_14_0_1_xq/janggi-85de3dae670a.nnue

make clean
make build ARCH=x86-64 largeboards=yes all=yes

make build ARCH=x86-64 largeboards=yes nnue=yes NNUE_PATH=./nnue/janggi.nnue all=yes

```

```commandline
curl -L -o fairy_sf_14.zip https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14.zip
unzip fairy_sf_14.zip
cd Fairy-Stockfish-fairy_sf_14/src/

curl -o nn-3475407dc199.nnue https://tests.stockfishchess.org/api/nn/nn-3475407dc199.nnue
```


```commandline
make clean
make build ARCH=apple-silicon largeboard=yes LARGEBOARDS=yes CXXFLAGS="-std=c++17 -DLARGEBOARD -DALL_VARIANTS"
make build ARCH=x86-64-modern COMP=clang LARGEBOARDS=yes


./fairy-stockfish
uci
```

```commandline
brew install cmake
rm -rf build
mkdir build
cd build
# do not support janggi in lts
brew install fairy-stockfish

git clone https://github.com/fairy-stockfish/Fairy-Stockfish.git
make build ARCH=x86-64-largeboard

```



```
git clone https://github.com/fairy-stockfish/Fairy-Stockfish.git
cd Fairy-Stockfish/src
make build ARCH=apple-silicon largeboard=yes

or
make build ARCH=x86-64-modern largeboard=yes
```

```
fairy-stockfish
which fairy-stockfish

pip install fastapi uvicorn pydantic-settings psutil

uvicorn app.main:app --reload
```