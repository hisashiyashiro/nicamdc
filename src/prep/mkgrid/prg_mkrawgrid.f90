!-------------------------------------------------------------------------------
!>
!! Program mkrawgrid
!!
!! @par Description
!!          Making grid systems based on the icosahedral grid configuration
!!
!! @author  H.Tomita
!!
!! @par History
!! @li      2004-02-17 (H.Tomita)  Imported from igdc-4.33
!! @li      2013-05-1  (H.Yashiro) NICAM-DC
!!
!<
program mkrawgrid
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use mod_precision
  use mod_debug
  use mod_adm, only: &
     ADM_LOG_FID,     &
     ADM_MULTI_PRC,   &
     ADM_proc_init,   &
     ADM_proc_finish, &
     ADM_setup
  use mod_fio, only: &
     FIO_setup
  use mod_comm, only: &
     COMM_setup
  use mod_cnst, only: &
     CNST_setup
  use mod_grd, only: &
     GRD_output_hgrid
  use mod_mkgrd, only: &
     MKGRD_setup,        &
     MKGRD_standard,     &
     MKGRD_spring,       &
     MKGRD_OUT_BASENAME, &
     MKGRD_OUT_io_mode
  !-----------------------------------------------------------------------------
  implicit none
  !-----------------------------------------------------------------------------
  !
  !++ parameters & variables
  !
  !=============================================================================

  call ADM_proc_init(ADM_MULTI_PRC)

  !---< admin module setup >---
  call ADM_setup('mkrawgrid.cnf')

  !---< I/O module setup >---
  call FIO_setup

  !---< comm module setup >---
  call COMM_setup

  !---< cnst module setup >---
  call CNST_setup

  !---< mkgrid module setup >---
  call MKGRD_setup

  !########## main ##########

  call MKGRD_standard

  call MKGRD_spring

  call GRD_output_hgrid( basename      = MKGRD_OUT_BASENAME, &
                         output_vertex = .false.,            &
                         io_mode       = MKGRD_OUT_io_mode   )

  !########## Finalize ##########

  !--- all processes stop
  call ADM_proc_finish

  stop
end program mkrawgrid
!-------------------------------------------------------------------------------
