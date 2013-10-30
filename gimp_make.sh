#!/bin/bash

echo "gimp make srcipt."

LIST_PACKAGE=" git-core intltool libjpeg-dev libopenexr-dev librsvg2-dev libtiff4-dev python-dev python-gtk2-dev libexif-dev liblcms1-dev libgtk2.0-dev gnome-doc-utils gtk-doc-tools libdevhelp-dev devhelp libdevhelp-dev liblzma-dev libbz2-dev libgexiv2-dev"

INST_DIR=$HOME


usage_exit() {
        echo "Usage: gimp_make.sh [--apt] [--prefix path] [--offall] ..." 1>&2
        exit 1
}





GETOPT=`getopt -q -o h -l apt,prefix,static_ver,offall,glib,babl,gegl,gtk,gimp,help: -- "$@"` ; [ $? != 0 ] && usage_exit
eval set -- "$GETOPT"


while true
do
  case $1 in
  --apt)	APT=true	; shift
        ;;
  --prefix)	INST_DIR=$2	; shift 2
        ;;
  --static_var)	STATIC=true	; shift
        ;;
  --offall)	OFFALL=true	; shift
        ;;
  --glib)	GLIB=true	; shift
        ;;
  --gabl)	BABL=true	; shift
        ;;
  --gele)	GEGL=true	; shift
        ;;
  --gtk)	GTK= true	; shift
        ;;
  --gimp)	GIMP=true	; shift
        ;;
  --help)       usage_exit	; shift
        ;;
  -h)	usage_exit
        ;;
  --)	shift ; break
        ;;
  *)	usage_exit
        ;;
  esac
done


#aptインストーラ起動
if [ $APT ]; then
	echo "apt-get"
	sudo apt-get update
	sudo apt-get install ${LIST_PACKAGE} -y
	exit
fi

#作業ディレクトリの設定
INST_DIR="$INST_DIR/gimp-x.x"
WORK_DIR="$INST_DIR/src"

#インストール無効化
if [ $OFFALL ] ; then
	GLIB_INST=false
	BABL_INST=false
	GEGL_INST=false
	GTK_INST=false
	GIMP_INST=false
else
	GLIB_INST=true
	BABL_INST=true
	GEGL_INST=true
	GTK_INST=true
	GIMP_INST=true
fi

#インストール有効化
if [ $GLIB ] ; then
	GLIB_INST=true
fi

if [ $BABL ] ; then
	BABL_INST=true
fi

if [ $GEGL ] ; then
	GEGL_INST=true
fi

if [ $GTK ] ; then
	GTK_INST=true
fi

if [ $GIMP ] ; then
	GIMP_INST=true
fi







Compile(){
	echo -e "***compile start:`basename ${REPO}`***\n"
	pushd ${WORK_DIR}

	#  ソースの取得
	if [ "" = "${PACK}" ] ; then
		git clone ${REPO}
		cd `basename ${REPO}`
		if [ 0 -eq ${ALLUPDATE} ] ; then
			git pull
		fi
		./autogen.sh --prefix=${INST_DIR}
		if [ 0 -ne ${?} ] ; then
			echo "install miss:`basename ${REPO}`"
			echo "repository path:${REPO}"
			exit 1
		else
			echo -e "meta install result:`basename ${REPO}`\n"
		fi	
	#  圧縮パッケージの場合
	elif [ "" != "${PACK}" ] ; then
		if [ ! -e `basename ${PACK}` ] ; then
			wget -m --no-passive-ftp ${PACK}
		fi
			if [ "" != "`echo \"${PACK}\"|grep .bz2`" ] ; then
				#bz2
				tar jxf `basename ${PACK}`
			else
				#xz
				tar -Jxvf `basename ${PACK}`
			fi
		#  圧縮ファイル名からフォルダ名を得る
		#PACK_DIR=`basename ${PACK} .tar.bz2`
		PACK_DIR=`basename ${PACK_DIR} .tar.xz`
		cd ${PACK_DIR}
		./configure --prefix=${INST_DIR}
		if [ 0 -ne ${?} ] ; then
			echo "install miss:`basename ${PACK}`"
			echo "repository path:${PACK}"
			exit 1
		else
			echo -e "meta install result:`basename ${PACK}`\n"
		fi
	fi

	#  コンパイル
	make -j5
	make check
	make install
	if [ 0 -ne ${?} ] ; then
		echo "install miss:`basename ${REPO}`"
		echo "repository path:${REPO}"
		exit 1
	else
		echo -e "meta install result:`basename ${REPO}`\n"
	fi
	
	REPO=""
	PACK=""
	popd
}



#インストールディレクトリの確保
if [ ! -d "$INST_DIR" ] ; then
	mkdir -p "$INST_DIR"
fi

if [ ! -w "$INST_DIR" ] ; then
	echo "エラー：\"$INST_DIR\"に対して書き込み権限がありませんでした"
	exit
fi

#インストールディレクトリの確保
if [ ! -d "$WORK_DIR" ] ; then
	mkdir -p "$WORK_DIR"
fi

if [ ! -w "$WORK_DIR" ] ; then
	echo "エラー：\"$WORK_DIR\"に対して書き込み権限がありませんでした"
	exit
fi



# 環境変数のSET
export PATH="${INST_DIR}/bin:$PATH"
export PKG_CONFIG_PATH="${INST_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="${INST_DIR}/lib:${LD_LIBRARY_PATH}"
export CFLAGS="-march=native -O2" 
#export CFLAGS=“-march=native:$CFLAGS”



# GLIB
REPO=http://git.gnome.org/browse/glib
PACK=""
if [ $GLIB_INST ] ; then
	Compile
else
	echo "tes:${GLIB_INST}"
fi


# BABL
REPO=http://git.gnome.org/browse/babl
#REPO=git://git.gnome.org/babl
PACK=""
if [ ${BABL_INST} ] ; then
	Compile
fi


# GEGL
REPO=http://git.gnome.org/browse/gegl
#PACK=ftp://ftp.gimp.org/pub/gegl/0.1/gegl-0.1.8.tar.bz2
if [ ${GEGL_INST} ] ; then
	Compile
fi


# GTKP
REPO=http://git.gnome.org/browse/gtk+
#PACK=ftp://ftp.gnome.org/pub/GNOME/sources/gtk+/2.24/gtk+-2.24.7.tar.xz
#未チェック
#PACK=ftp://ftp.gnome.org/pub/GNOME/sources/gtk+/2.24/gtk+-2.24.8.tar.xz
if [ ${GTK_INST} ] ; then
	pushd ${WORK_DIR}
	#バージョン・ダウンを行う。
	#バージョンは[git branch -r]で出てくる一覧から選ぶ。
	git clone ${REPO}
	pushd `basename ${REPO}`
	git checkout origin/gtk-2-24
	git checkout -b 2.24
	popd
	popd
	Compile
fi


# CAIRO(PANGOに使う？)
COMMENT="
REPO=http://git.gnome.org/browse/murrine
PACK=""
if [ 0 -eq ${PANGO} ] ; then
	Compile
fi
"

# PANGO
#10.04環境では不要。かつコンパイルできない。
COMMENT="
REPO=http://git.gnome.org/browse/pango
PACK=""
if [ 0 -eq ${PANGO} ] ; then
	Compile
fi
"


# GIMP
REPO=git://git.gnome.org/gimp
if [ ${GIMP_INST} ] ; then
	Compile
fi



