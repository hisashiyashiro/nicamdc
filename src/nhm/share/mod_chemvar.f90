!-------------------------------------------------------------------------------
!>
!! Tracer variable module
!!
!! @par Description
!!         This module contains the chemical or general-perpose tracer variables
!!
!! @author H.Yashiro
!!
!! @par History
!! @li      2012-11-07 (H.Yashiro)  [NEW]
!!
!<
module mod_chemvar
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mod_precision
  use mod_stdio
  use mod_debug
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: CHEMVAR_setup
  public :: chemvar_getid

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  integer,                 public, parameter   :: CHEM_TRC_vlim = 100
  integer,                 public              :: CHEM_TRC_vmax = 1
  character(len=16),       public, allocatable :: CHEM_TRC_name(:) ! short name  of tracer
  character(len=H_SHORT), public, allocatable :: CHEM_TRC_desc(:) ! description of tracer

  !-----------------------------------------------------------------------------
  !
  !++ Private procedures
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  !> Setup
  subroutine CHEMVAR_setup
    use mod_adm, only: &
       ADM_proc_stop
    implicit none

    namelist /CHEMVARPARAM/ &
       CHEM_TRC_vmax

    integer :: nq
    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    write(IO_FID_LOG,*)
    write(IO_FID_LOG,*) '+++ Module[chemvar]/Category[nhm share]'
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=CHEMVARPARAM,iostat=ierr)
    if ( ierr < 0 ) then
       write(IO_FID_LOG,*) '*** CHEMVARPARAM is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,          *) 'xxx Not appropriate names in namelist CHEMVARPARAM. STOP.'
       write(IO_FID_LOG,*) 'xxx Not appropriate names in namelist CHEMVARPARAM. STOP.'
       call ADM_proc_stop
    endif
    write(IO_FID_LOG,nml=CHEMVARPARAM)

    allocate( CHEM_TRC_name(CHEM_TRC_vmax) )
    allocate( CHEM_TRC_desc(CHEM_TRC_vmax) )

    do nq = 1, CHEM_TRC_vmax
       write(CHEM_TRC_name(nq),'(A,I3.3)') 'passive', nq
       write(CHEM_TRC_desc(nq),'(A,I3.3)') 'passive_tracer_no', nq
    enddo

    return
  end subroutine CHEMVAR_setup

  !-----------------------------------------------------------------------------
  function chemvar_getid( tracername )
    use mod_adm, only: &
       ADM_proc_stop
    implicit none

    character(len=*), intent(in) :: tracername
    integer                      :: chemvar_getid

    character(len=16) :: tname
    integer           :: itrc
    !---------------------------------------------------------------------------

    tname = trim(tracername)

    chemvar_getid = -1

    do itrc = 1, CHEM_TRC_vmax
       if ( tname == CHEM_TRC_name(itrc) ) then
          chemvar_getid = itrc
          return
       endif
    enddo

    if ( chemvar_getid <= 0 ) then
       write(IO_FID_LOG,*) 'xxx INDEX does not exist =>', tname
       call ADM_proc_stop
    endif

  end function chemvar_getid

end module mod_chemvar
!-------------------------------------------------------------------------------
