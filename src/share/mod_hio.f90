!-------------------------------------------------------------------------------
!>
!! File I/O module
!!
!! @par Description
!!         This module is continer for file I/O (PaNDa on HDF5, POH5 format)
!!
!! @author T.Inoue
!!
!! @par History
!! @li      2016-02-19 (T.Inoue)   [NEW]
!!
!<
module mod_hio
  !
  !++ Used modules
  !
  use mod_precision
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedures
  !
  public :: HIO_setup
  public :: HIO_input
  public :: HIO_seek
  public :: HIO_output
  public :: HIO_close
  public :: HIO_finalize

  interface HIO_input
     module procedure HIO_input_SP
     module procedure HIO_input_DP
  end interface HIO_input

  interface HIO_output
     module procedure HIO_output_SP
     module procedure HIO_output_DP
  end interface HIO_output

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  !--- character length
  integer, public, parameter :: HIO_HSHORT =  16 !< character length for short var.
  integer, public, parameter :: HIO_HMID   =  64 !< character length for middle var.
  integer, public, parameter :: HIO_HLONG  = 256 !< character length for long var.

  !--- data type
  integer, public, parameter :: HIO_REAL4    = 0 !< ID for 4byte real
  integer, public, parameter :: HIO_REAL8    = 1 !< ID for 8byte real
  integer, public, parameter :: HIO_INTEGER4 = 2 !< ID for 4byte int
  integer, public, parameter :: HIO_INTEGER8 = 3 !< ID for 8byte int

  !--- data endian
  integer, public, parameter :: HIO_UNKNOWN_ENDIAN = 0 !< ID for unknown endian
  integer, public, parameter :: HIO_LITTLE_ENDIAN  = 1 !< ID for little endian
  integer, public, parameter :: HIO_BIG_ENDIAN     = 2 !< ID for big endian

  !--- topology
  integer, public, parameter :: HIO_ICOSAHEDRON = 0 !< ID for ico grid
  integer, public, parameter :: HIO_IGA_LCP     = 1 !< ID for LCP grid
  integer, public, parameter :: HIO_IGA_MLCP    = 2 !< ID for MLCP grid

  !--- file mode (partial or complete)
  integer, public, parameter :: HIO_SPLIT_FILE = 0 !< ID for split(partical) file
  integer, public, parameter :: HIO_INTEG_FILE = 1 !< ID for integrated(complete) file

  !--- proccessor type
  integer, public, parameter :: HIO_SINGLE_PROC = 0 !< ID for single processor
  integer, public, parameter :: HIO_MULTI_PROC  = 1 !< ID for multi processor

  !--- action type
  integer, public, parameter :: HIO_FREAD   = 0 !< ID for read file
  integer, public, parameter :: HIO_FWRITE  = 1 !< ID for write file
  integer, public, parameter :: HIO_FAPPEND = 2 !< ID for append file

  !--- data dump type
  integer, public, parameter :: HIO_DUMP_OFF      = 0 !< Dumping off
  integer, public, parameter :: HIO_DUMP_HEADER   = 1 !< Dump header only
  integer, public, parameter :: HIO_DUMP_ALL      = 2 !< Dump all
  integer, public, parameter :: HIO_DUMP_ALL_MORE = 3 !< Dump all and more

  !> struct for package infomation
  type, public :: headerinfo
     character(len=HIO_HLONG) :: fname         !< file name
     character(len=HIO_HMID)  :: description   !< file description
     character(len=HIO_HLONG) :: note          !< longer note of file
     integer                  :: num_of_var    !< number of data
     integer                  :: fmode         !< file mode(0,1,2)
     integer                  :: endiantype    !< endian type(0,1,2)
     integer                  :: grid_topology !< grid topology(0,1,2)
     integer                  :: glevel        !< glevel
     integer                  :: rlevel        !< rlevel
     integer                  :: num_of_rgn    !< number of region
     integer, pointer         :: rgnid(:)      !< array of region id
  endtype headerinfo

  !> struct for data infomation
  type, public :: datainfo
     character(len=HIO_HSHORT) :: varname      !< variable name
     character(len=HIO_HMID)   :: description  !< variable description
     character(len=HIO_HSHORT) :: unit         !< unit of variable
     character(len=HIO_HSHORT) :: layername    !< layer name
     character(len=HIO_HLONG)  :: note         !< longer note of variable
     integer(DP)               :: datasize     !< data size
     integer                   :: datatype     !< data type(0,1,2,3)
     integer                   :: num_of_layer !< number of layer
     integer                   :: num_of_step  !< number of step
  endtype datainfo

  !-----------------------------------------------------------------------------
  !
  !++ Private procedures
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  integer,                  private, parameter :: HIO_nmaxfile = 64
  character(len=HIO_HLONG), private            :: HIO_fname_list(HIO_nmaxfile)
  integer,                  private            :: HIO_fid_list  (HIO_nmaxfile)
  integer,                  private            :: HIO_fid_count = 1

  type(headerinfo), private :: hinfo
  type(datainfo),   private :: dinfo

  integer, private, parameter :: max_num_of_data = 2500 !--- max time step num
  integer, private, parameter :: preclist(0:3) = (/ 4, 8, 4, 8 /)
  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  !> Setup this module.
  !!
  !! Must be called first.
  !!
  subroutine HIO_setup
    use mod_adm, only: &
       ADM_prc_me,  &
       ADM_prc_tab, &
       ADM_glevel,  &
       ADM_rlevel,  &
       ADM_lall
    implicit none

    integer, allocatable :: prc_tab(:)
    !---------------------------------------------------------------------------

    write(ADM_LOG_FID,*)
    write(ADM_LOG_FID,*) '+++ Module[hio]/Category[common share]'

    ! dummy call
    call DEBUG_rapstart('FILEIO_in')
    call DEBUG_rapend  ('FILEIO_in')
    call DEBUG_rapstart('FILEIO_out')
    call DEBUG_rapend  ('FILEIO_out')

    allocate( prc_tab(ADM_lall) )

    prc_tab(1:ADM_lall) = ADM_prc_tab(1:ADM_lall,ADM_prc_me)-1

    call hio_syscheck()
    call hio_put_commoninfo( HIO_SPLIT_FILE,  &
                             HIO_BIG_ENDIAN,  &
                             HIO_ICOSAHEDRON, &
                             ADM_glevel,      &
                             ADM_rlevel,      &
                             ADM_lall,        &
                             prc_tab          )

    deallocate(prc_tab)

    allocate( hinfo%rgnid(ADM_lall) )

    return
  end subroutine HIO_setup

  !-----------------------------------------------------------------------------
  !> Get file ID of given basename.
  !!
  !! Open it if not opened yet.
  !!
  subroutine HIO_getfid( &
       fid,      &
       basename, &
       rwtype,   &
       pkg_desc, &
       pkg_note  )
    use mod_adm, only: &
       ADM_prc_me
    implicit none

    integer,          intent(out) :: fid      !< file ID
    character(len=*), intent(in)  :: basename !< basename of file
    integer,          intent(in)  :: rwtype   !< file access type
    character(len=*), intent(in)  :: pkg_desc !< package(file) description
    character(len=*), intent(in)  :: pkg_note !< package(file) note

    character(len=HIO_HSHORT) :: rwname(0:2)
    data rwname / 'READ','WRITE','APPEND' /

    character(len=HIO_HLONG) :: fname
    integer                  :: n
    !---------------------------------------------------------------------------

    !--- search existing file
    fid = -1
    do n = 1, HIO_fid_count
       if ( basename == HIO_fname_list(n) ) fid = HIO_fid_list(n)
    enddo

    if ( fid < 0 ) then ! file registration
       !--- register new file and open
       call hio_mk_fname(fname,trim(basename),'pe',ADM_prc_me-1,6)
       call hio_register_file(fid,fname)

       if ( rwtype == HIO_FREAD ) then

!          call hio_dump_finfo(n,HIO_BIG_ENDIAN,HIO_DUMP_HEADER) ! dump to stdout(check)
          call hio_fopen(fid,HIO_FREAD)
          call hio_read_allinfo(fid)

       elseif( rwtype == HIO_FWRITE ) then

          call hio_fopen(fid,HIO_FWRITE)
          call hio_put_write_pkginfo(fid,pkg_desc,pkg_note)

       elseif( rwtype == HIO_FAPPEND ) then

          call hio_fopen(fid,HIO_FAPPEND)
          call hio_read_pkginfo(fid)
          call hio_write_pkginfo(fid)

       endif

       write(ADM_LOG_FID,'(1x,A,A,A,I3)') '*** [HIO] File registration (ADVANCED) : ', &
                            trim(rwname(rwtype)),' - ', HIO_fid_count
       write(ADM_LOG_FID,'(1x,A,I3,A,A)') '*** fid= ', fid, ', name: ', trim(fname)

       HIO_fname_list(HIO_fid_count) = trim(basename)
       HIO_fid_list  (HIO_fid_count) = fid
       HIO_fid_count = HIO_fid_count + 1
    endif

    return
  end subroutine HIO_getfid

  !-----------------------------------------------------------------------------
  !> Input(read) one variable at one step.
  subroutine HIO_input_SP( &
       var,           &
       basename,      &
       varname,       &
       layername,     &
       k_start,       &
       k_end,         &
       step,          &
       allow_missingq ) !--- optional
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_gall,      &
       ADM_lall
    implicit none

    real(SP),         intent(out) :: var(:,:,:) !< variable(ij,k,l)
    character(len=*), intent(in)  :: basename   !< basename of file
    character(len=*), intent(in)  :: varname    !< variable name
    character(len=*), intent(in)  :: layername  !< layer name
    integer,          intent(in)  :: k_start    !< start index of vertical level
    integer,          intent(in)  :: k_end      !< end   index of vertical level
    integer,          intent(in)  :: step       !< step to be read

    logical, intent(in), optional :: allow_missingq !< if data is missing, set value to zero, else execution stops.

    real(SP) :: var4(ADM_gall,k_start:k_end,ADM_lall)
    real(DP) :: var8(ADM_gall,k_start:k_end,ADM_lall)

    integer(DP) :: ts !! time_start
    integer(DP) :: te !! time_end

    integer :: did, fid
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('FILEIO_in')

    !--- search/register file
    call HIO_getfid( fid, basename, HIO_FREAD, '', '' )

    !--- seek data ID and get information
    call hio_seek_datainfo(did,fid,varname,step)
    call hio_get_datainfo(fid,did,dinfo)

    !--- verify
    if ( did == -1 ) then
       if ( present(allow_missingq) ) then
          if ( allow_missingq ) then
             write(ADM_LOG_FID,*) '*** [INPUT]/[HIO] data not found! : ', &
                                  'varname= ',trim(varname),', step=',step
             write(ADM_LOG_FID,*) '*** [INPUT]/[HIO] Q Value is set to 0.'

             var(:,k_start:k_end,:) = 0.0_SP

             call DEBUG_rapend('FILEIO_in')
             return
          endif
       else
          write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] data not found! : ', &
                               'varname= ',trim(varname),', step=',step
          call ADM_proc_stop
       endif
    endif

    if ( dinfo%layername /= layername ) then
       write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] layername mismatch! ', &
                            '[',trim(dinfo%layername),':',trim(layername),']'
       call ADM_proc_stop
    elseif( dinfo%num_of_layer /= k_end-k_start+1 ) then
       write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] num_of_layer mismatch! ', &
                            dinfo%num_of_layer,k_end-k_start+1
       call ADM_proc_stop
    endif

    !--- read data
    if ( dinfo%datatype == HIO_REAL4 ) then

       call hio_read_data(fid,did,step,ts,te,var4(:,:,:))
       var(:,k_start:k_end,:) = real( var4(:,1:dinfo%num_of_layer,:), kind=SP )

    elseif( dinfo%datatype == HIO_REAL8 ) then

       call hio_read_data(fid,did,step,ts,te,var8(:,:,:))
       var(:,k_start:k_end,:) = real( var8(:,1:dinfo%num_of_layer,:), kind=SP )

    endif

    call DEBUG_rapend('FILEIO_in')

    return
  end subroutine HIO_input_SP

  !-----------------------------------------------------------------------------
  !> Input(read) one variable at one step.
  subroutine HIO_input_DP( &
       var,           &
       basename,      &
       varname,       &
       layername,     &
       k_start,       &
       k_end,         &
       step,          &
       allow_missingq ) !--- optional
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_gall,      &
       ADM_lall
    implicit none

    real(DP),         intent(out) :: var(:,:,:) !< variable(ij,k,l)
    character(len=*), intent(in)  :: basename   !< basename of file
    character(len=*), intent(in)  :: varname    !< variable name
    character(len=*), intent(in)  :: layername  !< layer name
    integer,          intent(in)  :: k_start    !< start index of vertical level
    integer,          intent(in)  :: k_end      !< end   index of vertical level
    integer,          intent(in)  :: step       !< step to be read

    logical, intent(in), optional :: allow_missingq !< if data is missing, set value to zero, else execution stops.

    real(SP) :: var4(ADM_gall,k_start:k_end,ADM_lall)
    real(DP) :: var8(ADM_gall,k_start:k_end,ADM_lall)

    integer(DP) :: ts !! time_start
    integer(DP) :: te !! time_end

    integer :: did, fid
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('FILEIO_in')

    !--- search/register file
    call HIO_getfid( fid, basename, HIO_FREAD, '', '' )

    !--- seek data ID and get information
    call hio_seek_datainfo(did,fid,varname,step)
    call hio_get_datainfo(fid,did,dinfo)

    !--- verify
    if ( did == -1 ) then
       if ( present(allow_missingq) ) then
          if ( allow_missingq ) then
             write(ADM_LOG_FID,*) '*** [INPUT]/[HIO] data not found! : ', &
                                  'varname= ',trim(varname),', step=',step
             write(ADM_LOG_FID,*) '*** [INPUT]/[HIO] Q Value is set to 0.'

             var(:,k_start:k_end,:) = 0.0_DP

             call DEBUG_rapend('FILEIO_in')
             return
          endif
       else
          write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] data not found! : ', &
                               'varname= ',trim(varname),', step=',step
          call ADM_proc_stop
       endif
    endif

    if ( dinfo%layername /= layername ) then
       write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] layername mismatch! ', &
                            '[',trim(dinfo%layername),':',trim(layername),']'
       call ADM_proc_stop
    elseif( dinfo%num_of_layer /= k_end-k_start+1 ) then
       write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] num_of_layer mismatch! ', &
                            dinfo%num_of_layer,k_end-k_start+1
       call ADM_proc_stop
    endif

    !--- read data
    if ( dinfo%datatype == HIO_REAL4 ) then

       call hio_read_data(fid,did,step,ts,te,var4(:,:,:))
       var(:,k_start:k_end,:) = real( var4(:,1:dinfo%num_of_layer,:), kind=DP )

    elseif( dinfo%datatype == HIO_REAL8 ) then

       call hio_read_data(fid,did,step,ts,te,var8(:,:,:))
       var(:,k_start:k_end,:) = real( var8(:,1:dinfo%num_of_layer,:), kind=DP )

    endif

    call DEBUG_rapend('FILEIO_in')

    return
  end subroutine HIO_input_DP

  !-----------------------------------------------------------------------------
  !> Read in all steps of given `varname`, returns total data
  !! size(`num_of_step`) and mid of (time_start+time_end) of each
  !! step(`data_date`).
  !!
  !! `start_step` is maximum step where `ctime < 0.5*(ts(step)+te(step))` is true.
  !!
  !! `prec` is presicion, 4 or 8.
  !!
  !! If `opt_periodic_year` is T, data_date(:,1) is set as cdate(1) on
  !! return, else cdate(:) is neglected.
  !!
  subroutine HIO_seek( &
       start_step,       &
       num_of_step,      &
       data_date,        &
       prec,             &
       basename,         &
       varname,          &
       layername,        &
       k_start,          &
       k_end,            &
       ctime,            &
       cdate,            &
       opt_periodic_year )
    use mod_adm, only: &
       ADM_proc_stop
    use mod_calendar, only: &
       calendar_ss2yh, &
       calendar_yh2ss
    implicit none

    integer,          intent(inout) :: start_step
    integer,          intent(inout) :: num_of_step
    integer,          intent(inout) :: data_date(6,max_num_of_data)
    integer,          intent(inout) :: prec
    character(len=*), intent(in)    :: basename
    character(len=*), intent(in)    :: varname
    character(len=*), intent(in)    :: layername      ! for verification only
    integer,          intent(in)    :: k_start, k_end ! for verification only
    real(DP),         intent(in)    :: ctime
    integer,          intent(in)    :: cdate(6)       ! cdate(1) is only used only when opt_periodic_year is T.
    logical,          intent(in)    :: opt_periodic_year

    integer(DP), allocatable :: ts(:)
    integer(DP), allocatable :: te(:)
    integer                  :: num_of_var

    real(DP) :: midtime !--- [sec]
    logical  :: startflag
    integer  :: did, fid
    integer  :: i
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('FILEIO_in')

    !--- search/register file
    call HIO_getfid( fid, basename, HIO_FREAD, '', '' )

    startflag = .false.

    call hio_get_num_of_var(fid,num_of_var)

    !--- seek data ID and get information
    call hio_seek_datainfo(did,fid,varname,i) ! i is meaningless, for compatibility
    call hio_get_datainfo (fid,did,dinfo)     ! here dinfo must contain actual ts(:) and te(:).
    num_of_step = dinfo%num_of_step

    allocate( ts(dinfo%num_of_step) )
    allocate( te(dinfo%num_of_step) )
    call hio_get_timeinfo(fid,did,ts,te)

    !--- verify
    if ( dinfo%layername /= layername ) then
       write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] layername mismatch! ', &
                            '[',trim(dinfo%layername),':',trim(layername),']'
       call ADM_proc_stop
    elseif( dinfo%num_of_layer /= k_end-k_start+1 ) then
       write(ADM_LOG_FID,*) 'xxx [INPUT]/[HIO] num_of_layer mismatch!', &
                            dinfo%num_of_layer,k_end-k_start+1
       call ADM_proc_stop
    endif

    do i = 1, num_of_step
       midtime = real( int( (ts(i)+te(i))*0.5_DP+1.0_DP, kind=DP ), kind=DP )
       call calendar_ss2yh( data_date(:,i), midtime )

       if ( opt_periodic_year ) then
          data_date(1,i) = cdate(1)
          call calendar_yh2ss( midtime, data_date(:,i) )
       endif

       if (       ( .not. startflag ) &
            .AND. ( ctime < midtime ) ) then
          startflag  = .true.
          start_step = i
          prec       = preclist(dinfo%datatype)
       endif
    enddo

    deallocate( ts )
    deallocate( te )

    call DEBUG_rapend('FILEIO_in')

    return
  end subroutine HIO_seek

  !-----------------------------------------------------------------------------
  !> Append data with data header
  subroutine HIO_output_SP( &
       var,       &
       basename,  &
       pkg_desc,  &
       pkg_note,  &
       varname,   &
       data_desc, &
       data_note, &
       unit,      &
       dtype,     &
       layername, &
       k_start,   &
       k_end,     &
       step,      &
       t_start,   &
       t_end,     &
       append     )
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_gall,      &
       ADM_lall
    use mod_cnst, only: &
       CNST_UNDEF4
    implicit none

    real(SP),         intent(in) :: var(:,:,:)
    character(len=*), intent(in) :: basename
    character(len=*), intent(in) :: pkg_desc
    character(len=*), intent(in) :: pkg_note
    character(len=*), intent(in) :: varname
    character(len=*), intent(in) :: data_desc
    character(len=*), intent(in) :: data_note
    character(len=*), intent(in) :: unit
    integer,          intent(in) :: dtype
    character(len=*), intent(in) :: layername
    integer,          intent(in) :: k_start, k_end
    integer,          intent(in) :: step
    real(DP),         intent(in) :: t_start, t_end

    logical,intent(in), optional :: append

    real(SP) :: var4(ADM_gall,k_start:k_end,ADM_lall)
    real(DP) :: var8(ADM_gall,k_start:k_end,ADM_lall)

    integer(DP) :: ts, te

    integer :: did, fid
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('FILEIO_out')

    !--- search/register file
    call HIO_getfid( fid, basename, HIO_FWRITE, pkg_desc, pkg_note )

    !--- append data to the file
    dinfo%varname      = varname
    dinfo%description  = data_desc
    dinfo%unit         = unit
    dinfo%layername    = layername
    dinfo%note         = data_note
    dinfo%datasize     = int( ADM_gall * ADM_lall * (k_end-k_start+1) * preclist(dtype), kind=DP )
    dinfo%datatype     = dtype
    dinfo%num_of_layer = k_end-k_start+1

    ts                 = int( t_start, kind=DP )
    te                 = int( t_end,   kind=DP )

    if ( dtype == HIO_REAL4 ) then

       var4(:,k_start:k_end,:) = real( var(:,k_start:k_end,:), kind=SP )
       where( var4(:,:,:) < (CNST_UNDEF4+1.0_SP) )
          var4(:,:,:) = CNST_UNDEF4
       endwhere

       call hio_put_write_datainfo_data(did,fid,step,ts,te,dinfo,var4(:,:,:))

    elseif( dtype == HIO_REAL8 ) then

       var8(:,k_start:k_end,:) = real( var(:,k_start:k_end,:), kind=DP )

       call hio_put_write_datainfo_data(did,fid,step,ts,te,dinfo,var8(:,:,:))

    else
       write(ADM_LOG_FID,*) 'xxx [OUTPUT]/[FIO] Unsupported datatype!', dtype
       call ADM_proc_stop
    endif

    call DEBUG_rapend('FILEIO_out')

    return
  end subroutine HIO_output_SP

  !-----------------------------------------------------------------------------
  !> Append data with data header
  subroutine HIO_output_DP( &
       var,       &
       basename,  &
       pkg_desc,  &
       pkg_note,  &
       varname,   &
       data_desc, &
       data_note, &
       unit,      &
       dtype,     &
       layername, &
       k_start,   &
       k_end,     &
       step,      &
       t_start,   &
       t_end,     &
       append     )
    use mod_adm, only: &
       ADM_proc_stop, &
       ADM_gall,      &
       ADM_lall
    use mod_cnst, only: &
       CNST_UNDEF4
    implicit none

    real(DP),         intent(in) :: var(:,:,:)
    character(len=*), intent(in) :: basename
    character(len=*), intent(in) :: pkg_desc
    character(len=*), intent(in) :: pkg_note
    character(len=*), intent(in) :: varname
    character(len=*), intent(in) :: data_desc
    character(len=*), intent(in) :: data_note
    character(len=*), intent(in) :: unit
    integer,          intent(in) :: dtype
    character(len=*), intent(in) :: layername
    integer,          intent(in) :: k_start, k_end
    integer,          intent(in) :: step
    real(DP),         intent(in) :: t_start, t_end

    logical,intent(in), optional :: append

    real(SP) :: var4(ADM_gall,k_start:k_end,ADM_lall)
    real(DP) :: var8(ADM_gall,k_start:k_end,ADM_lall)

    integer(DP) :: ts, te

    integer :: did, fid
    !---------------------------------------------------------------------------

    call DEBUG_rapstart('FILEIO_out')

    !--- search/register file
    call HIO_getfid( fid, basename, HIO_FWRITE, pkg_desc, pkg_note )

    !--- append data to the file
    dinfo%varname      = varname
    dinfo%description  = data_desc
    dinfo%unit         = unit
    dinfo%layername    = layername
    dinfo%note         = data_note
    dinfo%datasize     = int( ADM_gall * ADM_lall * (k_end-k_start+1) * preclist(dtype), kind=DP )
    dinfo%datatype     = dtype
    dinfo%num_of_layer = k_end-k_start+1

    ts                 = int( t_start, kind=DP )
    te                 = int( t_end,   kind=DP )

    if ( dtype == HIO_REAL4 ) then

       var4(:,k_start:k_end,:) = real( var(:,k_start:k_end,:), kind=SP )
       where( var4(:,:,:) < (CNST_UNDEF4+1.0_SP) )
          var4(:,:,:) = CNST_UNDEF4
       endwhere

       call hio_put_write_datainfo_data(did,fid,step,ts,te,dinfo,var4(:,:,:))

    elseif( dtype == HIO_REAL8 ) then

       var8(:,k_start:k_end,:) = real( var(:,k_start:k_end,:), kind=DP )

       call hio_put_write_datainfo_data(did,fid,step,ts,te,dinfo,var8(:,:,:))

    else
       write(ADM_LOG_FID,*) 'xxx [OUTPUT]/[FIO] Unsupported datatype!', dtype
       call ADM_proc_stop
    endif

    call DEBUG_rapend('FILEIO_out')

    return
  end subroutine HIO_output_DP

  !-----------------------------------------------------------------------------
  subroutine HIO_close( &
       basename )
    use mod_adm, only: &
       ADM_prc_me
    implicit none

    character(len=*), intent(in) :: basename

    character(len=HIO_HLONG) :: fname

    integer :: fid
    integer :: n
    !---------------------------------------------------------------------------

    !--- search/register file
    do n = 1, HIO_fid_count
       if ( basename == HIO_fname_list(n) ) then
          fid = HIO_fid_list(n)

          call hio_fclose(fid)
          call hio_mk_fname(fname,trim(HIO_fname_list(n)),'pe',ADM_prc_me-1,6)

          write(ADM_LOG_FID,'(1x,A,I3,A,A)') &
          '*** [HIO] File close (ADVANCED) fid= ', fid, ', name: ', trim(fname)

          ! remove closed file info from the list
          HIO_fname_list(n) = ''
          HIO_fid_list  (n) = -1
       endif
    enddo

    return
  end subroutine HIO_close

  !-----------------------------------------------------------------------------
  subroutine HIO_finalize
    use mod_adm, only: &
       ADM_prc_me
    implicit none

    character(len=HIO_HLONG) :: fname
    integer                  :: n, fid
    !---------------------------------------------------------------------------

    do n = 1, HIO_fid_count
       fid = HIO_fid_list(n)

       call hio_fclose(fid)
       call hio_mk_fname(fname,trim(HIO_fname_list(n)),'pe',ADM_prc_me-1,6)

       write(ADM_LOG_FID,'(1x,A,I3,A,A)') &
       '*** [HIO] File close (poh5) fid= ', fid, ', name: ', trim(fname)
    enddo

    return
  end subroutine HIO_finalize

end module mod_hio
