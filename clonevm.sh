#!/bin/sh

DATASTORE=/vmfs/volumes/NAS
TEMPLATES=$DATASTORE/VMTemplates

display_usage() {
        echo "CloneVM"
        echo " A templating and cloning script written for ESXi hypervisors without vCenter"
        echo "Usage: $0 list"
        echo "          Displays all available templates in the default templates folder"
        echo "Usage: $0 template vmname"
        echo "          Creates and registers a new VM on the default datastore from the specified template in default templates folder"
        echo "Usage: $0 templatedir vmname"
        echo "          Creates and registers a new VM from specified template folder"
        echo "Usage: $0 templatedir vmdir"
        echo "          Creates and registers a new VM in the specified folder from specified template folder"
        echo ""
        echo "CloneVM is currently configured to use the following directories:"
        echo "          DATASTORE: $DATASTORE"
        echo "          TEMPLATES: $TEMPLATES"
}

if [ "$1" == "list" ]; then
        echo "Available Templates"
        ls $TEMPLATES
else
        if [ $# -lt 2 ]; then
                display_usage
        else

                #$2 = Target
                #$1 = Source

                if [ -d "/$1" ]; then
                        TEMPLATEDIR="/$1"
                        TEMPLATE=`basename $1`
                else
                        TEMPLATEDIR="$TEMPLATES/$1"
                        TEMPLATE=$1
                fi

                #Check if the parent directory exists as we are going to create the VM dir
                if [ -d `dirname /$2` ]; then
                        #Make sure the parent directory wasn't root, if so we're actually using default
                        if [ `dirname /$2` == "/" ]; then
                                echo "Creating in default DATASTORE"
                                TARGET=$2
                                TARGETDIR=$DATASTORE/$2
                        else
                                echo "Using exact path"
                                TARGET=`basename $2`
                                TARGETDIR=$2
                        fi
                else
                        echo "Creating in default DATASTORE"
                        TARGET=$2
                        TARGETDIR=$DATASTORE/$2
                fi

                if [ -d "$TEMPLATEDIR" ]; then
                        echo "Creating new VM $TARGET from $TEMPLATE in $TARGETDIR"

                        mkdir $TARGETDIR

                        count=`ls ${TEMPLATEDIR} | grep -v .log - | wc -l`
                        i=1
                        #Do the copy line by line to give some progress output!
                        for file in `ls ${TEMPLATEDIR} | grep -v .log -`; do
                                newfile=`echo $file | sed "s/${TEMPLATE}/${TARGET}/"`

                                echo "Creating file $i of $count: $newfile"
                                cp ${TEMPLATEDIR}/$file $TARGETDIR/$newfile
                                i=$((i+1))
                        done

                        echo "Post Processing"

                        cd $TARGETDIR

                        #update disk defintions
                        echo "Updating Disks"
                        for disk in `ls *.vmdk | grep -v "flat.vmdk" -`; do
                                sed -i -e "s/${TEMPLATE}/${TARGET}/g" -f $f
                        done

                        echo "Configuring VMX"
                        sed -i -e "s/${TEMPLATE}/${TARGET}/g" -f ${TARGET}.vmx

                        echo "Registering new VM with ESXi"
                         VMID=`vim-cmd solo/registervm $TARGETDIR/$TARGET.vmx`

                        echo "New VM $TARGET was registered with id $VMID"

                else
                        echo "Could not find template, try $0 list"
                fi

        fi
fi

