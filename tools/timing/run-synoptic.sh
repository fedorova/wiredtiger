#!/bin/sh

synoptic.sh --dumpInvariants=true --dumpInitialPartitionGraph=true --noRefinement=true --noCoarsening=true -c log-args.txt $@
