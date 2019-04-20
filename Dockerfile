FROM centos
ENV container=podman  
# sshd
RUN echo -e "qwerty\nqwerty\n" | passwd root
RUN yum install -y openssh-server && yum upgrade -y
RUN mkdir -p /var/run/sshd ; chmod -rx /var/run/sshd
# http://stackoverflow.com/questions/2419412/ssh-connection-stop-at-debug1-ssh2-msg-kexinit-sent
#RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
# Bad security, add a user and sudo instead!
RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
# http://stackoverflow.com/questions/18173889/cannot-access-centos-sshd-on-docker
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
# install gitolite and trac
RUN yum install -y epel-release 
RUN yum install -y gitolite3 python-babel python-backports \
python-backports-ssl_match_hostname python-genshi python-ipaddress \
python-setuptools nginx-all-modules postgresql-server unzip patch
RUN mkdir /root/trac
ADD trac_distrib/* /root/trac
RUN cd /root/trac/; unzip \*.zip; rm *.zip 
# RUN cd /root/trac/; tar -xvf \*.tar.\*; rm \*.tar.\*
# add patch
COPY install/patch_distrib/ /root/trac/patch_distrib
RUN cp -R /root/trac/patch_distrib/trac/* /root/trac/Trac-1.0.17/
RUN cd /root/trac/Trac-1.0.17; \
    patch -p1 < commitupdate.patch; \
    patch -p1 < quicksearch.patch; \
    patch -p1 < threaded_comments.patch
RUN cp -R /root/trac/patch_distrib/announcerplugin/* /root/trac/privateticketsplugin/trunk
RUN cp -R /root/trac/patch_distrib/privateticketsplugin/* /root/trac/privateticketsplugin/trunk
#RUN cd /root/trac/privateticketsplugin/trunk; \
#    patch -p1 < privateticket.patch
RUN cp -R /root/trac/patch_distrib/trac-subtickets-plugin-patch/* /root/trac/trac-subtickets-plugin-master
RUN cd /root/trac/trac-subtickets-plugin-master; \
    patch -p1 < recursion-validating.patch
# install trac
RUN cp -R /root/trac/patch_distrib/announcerplugin/* /root/trac/privateticketsplugin/trunk
RUN easy_install-2.7 /root/trac/Trac-1.0.17
RUN easy_install-2.7 /root/trac/regexlinkplugin
RUN easy_install-2.7 /root/trac/WikiReportMacro-master
RUN easy_install-2.7 /root/trac/wikiautocompleteplugin/trunk
RUN easy_install-2.7 /root/trac/trac-subtickets-plugin-master
RUN easy_install-2.7 /root/trac/trac-subcomponents-a86f0413121f
RUN easy_install-2.7 /root/trac/privateticketsplugin/trunk
RUN easy_install-2.7 /root/trac/announcerplugin/trunk
RUN easy_install-2.7 /root/trac/advancedticketworkflowplugin/1.2
RUN easy_install-2.7 /root/trac/accountmanagerplugin/tags/acct_mgr-0.4.4
RUN easy_install-2.7 /root/trac/tracwysiwygplugin/0.12
RUN easy_install-2.7 /root/trac/groupticketfieldsplugin/0.12/trunk
RUN easy_install-2.7 /root/trac/autocompleteusersplugin/trunk
RUN rm -R /root/trac

# add patch gitolite
ADD install/dot_distrib/gitolite/checkid/CHECKID /usr/share/gitolite3/VREF/
RUN chmod 755 /usr/share/gitolite3/VREF/CHECKID
ADD install/dot_distrib/gitolite/onlymerge/ONLYMERGE /usr/share/gitolite3/VREF/
RUN chmod 755 /usr/share/gitolite3/VREF/ONLYMERGE

ENTRYPOINT ["/sbin/init"]
CMD ["--log-level=info"]
STOPSIGNAL SIGRTMIN+3