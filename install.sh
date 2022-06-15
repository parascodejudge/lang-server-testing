#!/bin/bash
project=${PWD}
rm -rf $project/servers # remove project folder if present
mkdir $project/servers

# csharp
echo "------------------------------------------------C# Start------------------------------------------------"

sudo apt-get -y install wget
# Installing the microsoft packages ubuntu repo for dotnet
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y apt-transport-https
sudo apt-get update
sudo apt-get install -y dotnet-sdk-6.0
mkdir servers/csharp_language_server
cd servers/csharp_language_server
# Downloading the omnisharp release in csharp_language_server folder
wget https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.39.0/omnisharp-linux-x64-net6.0.tar.gz
tar -xf omnisharp-linux-x64-net6.0.tar.gz
rm omnisharp-linux-x64-net6.0.tar.gz
sudo ln -s $project/servers/csharp_language_server/OmniSharp /usr/bin/omnisharp
cd $project

echo "------------------------------------------------C# End------------------------------------------------"

# java
echo "------------------------------------------------Java Start------------------------------------------------"

sudo apt-get -y install openjdk-11-jdk
# Installing the JDTLS Script
sudo curl https://raw.githubusercontent.com/eruizc-dev/jdtls-launcher/master/install.sh | bash
# Soft Linking the script to root level
sudo ln -s ${HOME}/.local/opt/jdtls-launcher/jdtls-launcher.sh /usr/bin/jdtls

echo "------------------------------------------------Java End------------------------------------------------"


#php
echo "------------------------------------------------PHP Start------------------------------------------------"

sudo apt-get -y install npm
sudo npm i -g intelephense

echo "------------------------------------------------PHP End------------------------------------------------"

# cpp and c
echo "------------------------------------------------CPP/C Start------------------------------------------------"

sudo apt-get -y install clangd

echo "------------------------------------------------CPP/C End------------------------------------------------"

# ruby
echo "------------------------------------------------RUBY Start------------------------------------------------"

sudo apt-get -y install ruby gem
mkdir servers/ruby_language_server
# Installing Ruby Language Server
gem install --install-dir $project/servers/ruby_language_server solargraph
sudo ln -s $project/servers/ruby_language_server/bin/solargraph /usr/bin/solargraph

echo "------------------------------------------------RUBY End------------------------------------------------"

# python
echo "------------------------------------------------Python Start------------------------------------------------"

sudo apt-get -y install python3 python3-pip
sudo pip install python-lsp-server
# Adding a Extension to Python Language Server
sudo pip install "python-lsp-server[pyflakes]"

echo "------------------------------------------------Python End------------------------------------------------"

# bash
echo "------------------------------------------------JS Start------------------------------------------------"

sudo apt-get -y install npm
sudo npm i -g typescript typescript-language-server

echo "------------------------------------------------JS End------------------------------------------------"

# bash
echo "------------------------------------------------Bash Start------------------------------------------------"

sudo apt-get -y install npm
sudo npm i -g bash-language-server

echo "------------------------------------------------Bash End------------------------------------------------"

# kotlin
echo "------------------------------------------------Kotlin Start------------------------------------------------"

cd $project/servers
git clone https://github.com/fwcd/kotlin-language-server.git
cd kotlin-language-server
# Building the kotlin-language-server
./gradlew :server:installDist
sudo ln -s $project/servers/kotlin-language-server/server/build/install/server/bin/kotlin-language-server /usr/bin/kotlin-language-server
cd $project

echo "------------------------------------------------Kotlin End------------------------------------------------"

# Scala
echo "------------------------------------------------Scala Start------------------------------------------------"

sudo apt-get -y install scala
mkdir servers/scala_language_server
cd servers/scala_language_server
# Downloading the Scala Package Manager 'cs'
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d >cs
chmod +x cs
# Installing Scala Language Server
./cs install metals --install-dir $project/servers/scala_language_server
sudo ln -s $project/servers/scala_language_server/metals /usr/bin/metals
cd $project

echo "------------------------------------------------Scala End------------------------------------------------"

# Perl
echo "------------------------------------------------Perl Start------------------------------------------------"

sudo apt-get -y install perl libmoose-perl libcoro-perl libanyevent-perl
# Downloading the Perl Package Manager 'cpanm'
wget -O - http://cpanmin.us | sudo perl - --self-upgrade
# Installing Perl Language Server
sudo cpanm --notest PLS

echo "------------------------------------------------Perl End------------------------------------------------"

# R
echo "------------------------------------------------R Start------------------------------------------------"

# sudo apt-get -y install r-base
# # Installing R Language Server
# sudo R --no-save -e "install.packages('languageserver')"

echo "------------------------------------------------R End------------------------------------------------"

# Swift
echo "------------------------------------------------Swift Start------------------------------------------------"

sudo apt-get -y install clang libicu-dev
cd $project/servers/
# Downloading the swift latest release which also contains the swift language server
wget https://download.swift.org/swift-5.6.1-release/ubuntu2004/swift-5.6.1-RELEASE/swift-5.6.1-RELEASE-ubuntu20.04.tar.gz
tar -xvf swift-5.6.1-RELEASE-ubuntu20.04.tar.gz
rm swift-5.6.1-RELEASE-ubuntu20.04.tar.gz
sudo ln -s $project/servers/swift-5.6.1-RELEASE-ubuntu20.04/usr/bin/sourcekit-lsp /usr/bin/sourcekit-lsp
cd $project

echo "------------------------------------------------Swift End------------------------------------------------"

# Golang
echo "------------------------------------------------Go Start------------------------------------------------"

sudo apt-get -y install golang
# Installing Go Language Server
go install golang.org/x/tools/gopls@latest
sudo ln -s ${GOPATH}/bin/gopls /usr/bin/gopls

echo "------------------------------------------------Go End------------------------------------------------"
