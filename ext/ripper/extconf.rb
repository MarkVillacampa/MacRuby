#!ruby -s

require 'mkmf'
require 'rbconfig'

def main
  unless find_executable('bison')
    unless File.exist?('ripper.c') or File.exist?("#{$srcdir}/ripper.c")
      Logging.message 'missing bison; abort'
      return
    end
  end
  $objs = %w(ripper.o)
  $cleanfiles.concat %w(ripper.y ripper.c ripper.E ripper.output eventids1.c eventids2table.c)
  $defs << '-DRIPPER'
  $defs << '-DRIPPER_DEBUG' if $debug
  $VPATH << '$(topdir)' << '$(top_srcdir)'
  $INCFLAGS << ' -I$(topdir) -I$(top_srcdir) -I$(top_srcdir)/onig'
  $INCFLAGS << ' -I../../icu-1060' if `sw_vers -productVersion`.to_f <= 10.6
  $CFLAGS << ' -std=gnu99'
  create_makefile 'ripper'
end

main
