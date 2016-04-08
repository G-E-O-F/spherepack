module type_Workspace

    use, intrinsic :: iso_fortran_env, only: &
        wp => REAL64, &
        ip => INT32

    ! Explicit typing only
    implicit none

    ! Everything is private unless stated otherwise
    private
    public :: Workspace

    ! Declare derived data type
    type, abstract, public :: Workspace
        !----------------------------------------------------------------------
        ! Class variables
        !----------------------------------------------------------------------
        logical,                public :: initialized = .false.
        real (wp), allocatable, public :: legendre_workspace(:) ! work
        real (wp), allocatable, public :: forward_scalar(:)
        real (wp), allocatable, public :: forward_vector(:)
        real (wp), allocatable, public :: backward_scalar(:)
        real (wp), allocatable, public :: backward_vector(:)
        real (wp), allocatable, public :: real_harmonic_coefficients(:, :)
        real (wp), allocatable, public :: imaginary_harmonic_coefficients(:, :)
        real (wp), allocatable, public :: real_polar_harmonic_coefficients(:, :)
        real (wp), allocatable, public :: imaginary_polar_harmonic_coefficients(:, :)
        real (wp), allocatable, public :: real_azimuthal_harmonic_coefficients(:, :)
        real (wp), allocatable, public :: imaginary_azimuthal_harmonic_coefficients(:, :)
        !----------------------------------------------------------------------
    contains
        !----------------------------------------------------------------------
        ! Class methods
        !----------------------------------------------------------------------
        procedure, nopass, public :: get_lwork
        procedure, nopass, public :: get_ldwork
        procedure,         public :: destroy_workspace
        !----------------------------------------------------------------------
    end type Workspace


contains


    subroutine destroy_workspace(this)
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        class (Workspace), intent (in out) :: this
        !----------------------------------------------------------------------

        if (this%initialized .eqv. .false.) return

        ! Release memory
        if (allocated(this%legendre_workspace)) deallocate(this%legendre_workspace)
        if (allocated(this%forward_scalar)) deallocate(this%forward_scalar)
        if (allocated(this%forward_vector)) deallocate(this%forward_vector)
        if (allocated(this%backward_scalar)) deallocate(this%backward_scalar)
        if (allocated(this%backward_vector)) deallocate(this%backward_vector)
        if (allocated(this%real_harmonic_coefficients)) deallocate(this%real_harmonic_coefficients)
        if (allocated(this%imaginary_harmonic_coefficients)) deallocate(this%imaginary_harmonic_coefficients)
        if (allocated(this%real_polar_harmonic_coefficients)) deallocate(this%real_polar_harmonic_coefficients)
        if (allocated(this%imaginary_polar_harmonic_coefficients)) deallocate(this%imaginary_polar_harmonic_coefficients)
        if (allocated(this%real_azimuthal_harmonic_coefficients)) deallocate(this%real_azimuthal_harmonic_coefficients)
        if (allocated(this%imaginary_azimuthal_harmonic_coefficients)) deallocate(this%imaginary_azimuthal_harmonic_coefficients)

        ! Reset flag
        this%initialized = .false.

    end subroutine destroy_workspace


    pure function get_lwork( nlat, nlon ) result ( return_value )
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        integer (ip), intent (in) :: nlat
        integer (ip), intent (in) :: nlon
        integer (ip)              :: return_value
        !----------------------------------------------------------------------

        return_value = (4 * nlon + 2) * nlat

    end function get_lwork


    pure function get_ldwork( nlat ) result ( return_value )
        !----------------------------------------------------------------------
        ! Dictionary: calling arguments
        !----------------------------------------------------------------------
        integer (ip), intent (in) :: nlat
        integer (ip)              :: return_value
        !----------------------------------------------------------------------

        return_value = (3 * nlat * (nlat + 3) + 2)/2

    end function get_ldwork


end module type_Workspace
