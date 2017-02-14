from ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get install -y \
    tar \
    gzip \
    unzip \
    gcc \
    g++ \
    clang-3.6 \
    git \
    curl \
    wget \
    cmake \
    tree \
    diffstat \
    pkg-config \
    build-essential \
    tcpdump \
    silversearcher-ag \
    software-properties-common

RUN apt-add-repository ppa:brightbox/ruby-ng \
    && apt-get update && apt-get install -y \
    ruby$RB_RUBY_VERSION

# Setup home environment
RUN useradd -m dev \
  && chpasswd << "dev:dev" && echo "dev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dev_user && usermod -aG users dev \
  && mkdir -p /home/dev/bin \
  && mkdir -p /home/dev/.config \
  && mkdir -p /home/dev/lib
ENV PATH /home/dev/bin:$PATH
ENV PKG_CONFIG_PATH /home/dev/lib/pkgconfig
ENV LD_LIBRARY_PATH /home/dev/lib
ENV HOME /home/dev

## ruby environment
ENV RB_RUBY_VERSION 2.3
ENV BAKE_VERSION 2.30.0

COPY mapsize-0.2.2.gem mapsize-0.2.2.gem
ENV CONFIGURE_OPTS --disable-install-doc
RUN echo 'gem: --no-rdoc --no-ri' >> $HOME/.gemrc \
  && gem install rake \
  && gem install bundler \
  && gem install bake-toolkit -v $BAKE_VERSION \
  && gem install zip \
  && gem install rgen \
  && gem install rtext \
  && gem install mapsize-0.2.2.gem \
  && ruby -v

# install neovim
RUN apt-get install -y software-properties-common python-software-properties \
  && add-apt-repository ppa:neovim-ppa/unstable \
  && apt-get update && apt-get install -y \
    neovim \
    python-dev python-pip python3-dev python3-pip \
  && apt-get clean \
  && update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60 \
  && update-alternatives --config vi \
  && update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60 \
  && update-alternatives --config vim \
  && update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60 \
  && update-alternatives --config editor \
  && pip3 install neovim \
  && pip2 install neovim

# rust environment
RUN curl -sSf https://static.rust-lang.org/rustup.sh | sh
# RUN rustup update stable

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /var/shared/
RUN touch /var/shared/placeholder
RUN chown -R dev:dev /var/shared
VOLUME /var/shared

WORKDIR /home/dev
ENV HOME /home/dev

COPY bin /home/dev/bin
RUN curl -L https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh > ~/.bash_git
RUN mv /home/dev/bin/git-completion.bash /home/dev
COPY dotfiles/.git_template /home/dev/.git_template
COPY dotfiles/.profile_linux_work /home/dev/.profile
COPY dotfiles/.bashrc_linux_work /home/dev/.bashrc
COPY dotfiles/.bashrc_common /home/dev/.bashrc_common
COPY dotfiles/.gitconfig_linux_work /home/dev/.gitconfig
COPY dotfiles/.inputrc /home/dev/.inputrc
COPY dotfiles/.editrc /home/dev/.editrc
COPY dotfiles/.fzf.bash_common /home/dev/.fzf.bash_common
COPY dotfiles/.gemrc /home/dev/.gemrc
COPY dotfiles/.gitignore /home/dev/.gitignore
COPY dotfiles/.gitk /home/dev/.gitk
COPY dotfiles/.rake_cap_bash_autocomplete.sh /home/dev/.rake_cap_bash_autocomplete.sh
COPY dotfiles/.tmux.conf /home/dev/.tmux.conf

RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
  && ~/.fzf/install
RUN git clone https://github.com/rupa/z.git \
  && cp z/z.sh bin

# setup nvim
RUN git clone https://github.com/marcmo/vimfiles.git ~/.config/nvim \
  && mkdir -p $HOME/.config/nvim/autoload \
  && curl -L https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
        > $HOME/.config/nvim/autoload/plug.vim

# Link in shared parts of the home directory
RUN ln -s /var/shared/.ssh \
  && ln -s /var/shared/.bash_history \
  && ln -s /var/shared/.maintainercfg

RUN ln -sv /usr/bin/clang-3.6 /usr/bin/clang \
  && ln -sv /usr/bin/clang++-3.6 /usr/bin/clang++ \
  && ln -sv /usr/bin/clang-apply-replacements-3.6 /usr/bin/clang-apply-replacements \
  && ln -sv /usr/bin/clang-check-3.6 /usr/bin/clang-check \
  && ln -sv /usr/bin/clang-query-3.6 /usr/bin/clang-query \
  && ln -sv /usr/bin/clang-rename-3.6 /usr/bin/clang-rename \
  && ln -sv /usr/bin/clang-tblgen-3.6 /usr/bin/clang-tblgen \
  && ln -sv /usr/bin/clang-tidy-3.6 /usr/bin/clang-tidy

## newer make version
RUN wget http://ftp.gnu.org/gnu/make/make-4.2.tar.gz \
  && tar xfvz make-4.2.tar.gz
WORKDIR make-4.2
RUN ./configure \
  && make \
  && cp make /home/dev/bin
WORKDIR $HOME

RUN chown -R dev: /home/dev
USER dev
