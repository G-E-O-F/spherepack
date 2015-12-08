!*****************************************************************************************
!
!< Author:
! Jon Lo Kim Lin
!
!< Purpose:
!
! A modern Fortran (2003+) object-oriented spherepack wrapper for NCAR's SPHEREPACK 3.2
!
!*****************************************************************************************
!
module type_sphere_mod

    use type_workspace_mod, only: &
        workspace_t

    use type_grid_mod, only: &
        grid_t

    use type_vector_mod
    
    use, intrinsic :: iso_fortran_env, only: &
        REAL64, &
        INT32

    ! Explicit typing only
    implicit none

    ! Everything is private unless stated otherwise
    private
    public :: sphere_t

    !---------------------------------------------------------------------------------
    ! Dictionary: global variables confined to the module
    !---------------------------------------------------------------------------------
    integer, parameter    :: WP = REAL64       !! 64 bit real
    integer, parameter    :: IP = INT32        !! 32 bit integer
    character (200)       :: error_message     !! Probably long enough
    integer (IP)          :: allocate_status   !! To check allocation status
    integer (IP)          :: deallocate_status !! To check deallocation status
    !---------------------------------------------------------------------------------

    ! Declare derived data type
    type :: sphere_t

        ! All components are public unless stated otherwise
        !---------------------------------------------------------------------------------
        ! Initialization flag
        !---------------------------------------------------------------------------------
        logical                               :: initialized = .false. !! Instantiation status
        !---------------------------------------------------------------------------------
        ! Named constants
        !---------------------------------------------------------------------------------
        integer (IP)                          :: NLON   = 0              !! number of longitudinal points
        integer (IP)                          :: NLAT   = 0              !! number of latitudinal points
        integer (IP)                          :: NTRUNC = 0              !! triangular truncation limit
        integer (IP)                          :: ISYM   = 0              !! symmetries about the equator for scalar calculations
        integer (IP)                          :: ITYPE  = 0              !! symmetries about the equator for vector calculations
        integer (IP)                          :: NUMBER_OF_SYNTHESES = 0 !!
        !---------------------------------------------------------------------------------
        ! Complex spectal coefficients
        !---------------------------------------------------------------------------------
        complex (WP), dimension (:), allocatable    :: spec        !! Complex (scalar) coefficients
        !---------------------------------------------------------------------------------
        ! Derived data type
        !---------------------------------------------------------------------------------
        type (workspace_t), private                 :: workspace             !! Contains the various workspace arrays to invoke SPHERPACK 3.2
        type (grid_t)                               :: grid                  !! Spherical grid
        !---------------------------------------------------------------------------------
        ! Commonly used trigonometric functions
        !---------------------------------------------------------------------------------
        real (WP), dimension (:), allocatable       :: sint                 !! sin(theta): 0 <= theta <= pi
        real (WP), dimension (:), allocatable       :: cost                 !! cos(theta): 0 <= theta <= pi
        real (WP), dimension (:), allocatable       :: sinp                 !! sin(phi):   0 <=  phi  <= 2*pi
        real (WP), dimension (:), allocatable       :: cosp                 !! cos(phi):   0 <=  phi  <= 2*pi
        !---------------------------------------------------------------------------------
        ! The spherical unit vectors
        !---------------------------------------------------------------------------------
        real (WP), dimension (:, :, :), allocatable :: radial_unit_vector
        real (WP), dimension (:, :, :), allocatable :: polar_unit_vector
        real (WP), dimension (:, :, :), allocatable :: azimuthal_unit_vector
        !---------------------------------------------------------------------------------

    contains
        
        ! All method are private unless stated otherwise
        private

        !---------------------------------------------------------------------------------
        ! Public SPHEREPACK 3.2 methods
        !---------------------------------------------------------------------------------
        procedure, public                    :: Get_colatitude_derivative !! Vtsgs
        procedure, public                    :: Get_Gradient !! Gradgs
        procedure, public                    :: Invert_gradient !!  Igradgs
        procedure, public                    :: Get_Divergence !! Divgs
        procedure, public                    :: Invert_divergence !!Idivgs
        procedure, public                    :: Get_Vorticity !! Vrtgs
        procedure, public                    :: Invert_vorticity !! Ivrtgs
        procedure, public                    :: Invert_divergence_and_vorticity !! Idvtgs
        procedure, public                    :: Get_Scalar_laplacian !! Slapgs
        procedure, public                    :: Invert_helmholtz !! Islapgs
        procedure, public                    :: Get_Vector_laplacian !! Vlapgs
        procedure, public                    :: Invert_vector_laplacian !! Ivlapgs
        procedure, public                    :: Get_Stream_function_and_velocity_potential
        procedure, public                    :: Invert_stream_function_and_velocity_potential
        procedure, public                    :: Perform_grid_transfers
        procedure, public                    :: Perform_Geo_math_coordinate_transfers
        procedure, public                    :: Perform_scalar_analysis
        procedure, public                    :: Perform_scalar_synthesis
        procedure, public                    :: Perform_scalar_projection !! Shpg
        procedure, public                    :: Perform_vector_analysis
        procedure, public                    :: Perform_vector_synthesis
        procedure, public                    :: Get_Legendre_functions
        !procedure, public                    :: Get_Icosahedral_geodesic
        !procedure, public                    :: Get_Multiple_ffts
        procedure, nopass, public            :: Get_gaussian_weights_and_points !! Gaqd
        !procedure, public                    :: Get_Three_dimensional_sphere_graphics
        !---------------------------------------------------------------------------------
        ! Public complex methods
        !---------------------------------------------------------------------------------
        procedure, public                    :: Perform_complex_analysis
        procedure, public                    :: Perform_complex_synthesis
        !---------------------------------------------------------------------------------
        ! Additional public methods
        !---------------------------------------------------------------------------------
        procedure, non_overridable, public   :: Create
        procedure, non_overridable, public   :: Destroy
        procedure, non_overridable, public   :: Get_index
        procedure, non_overridable, public   :: Get_coefficient
        procedure, public                    :: Compute_surface_integral
        procedure, public                    :: Get_rotation_operator
        procedure, public                    :: Synthesize_from_spec
        !---------------------------------------------------------------------------------
        ! Private methods
        !---------------------------------------------------------------------------------
        procedure, non_overridable           :: Assert_initialized
        procedure                            :: Set_trigonometric_functions
        procedure                            :: Set_spherical_unit_vectors
        procedure                            :: Get_spherical_angle_components
        procedure                            :: Set_scalar_symmetries
        procedure                            :: Set_vector_symmetries
        final                                :: Finalize
        !---------------------------------------------------------------------------------

    end type sphere_t

contains
    !
    !*****************************************************************************************
    !
    subroutine Create( this, nlat, nlon, isym, itype, grid_type )
        !
        ! Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        integer (IP), intent (in)            :: nlat
        integer (IP), intent (in)            :: nlon
        integer (IP), intent (in), optional  :: isym      !! Either 0, 1, or 2
        integer (IP), intent (in), optional  :: itype     !! Either 0, 1, 2, 3, ..., 8
        character (*), intent (in), optional :: grid_type !! Either '(GAU)' or '(REG)'
        !--------------------------------------------------------------------------------

        !--------------------------------------------------------------------------------
        ! Check initialization flag
        !--------------------------------------------------------------------------------

        if ( this%initialized ) then
            print *, 'ERROR: You must destroy "sphere" before re-instantiating'
            return
        end if

        !--------------------------------------------------------------------------------
        ! Set constants
        !--------------------------------------------------------------------------------

        this%NLAT   = nlat
        this%NLON   = nlon
        this%NTRUNC = nlat - 1 !! Set triangular truncation
        this%NUMBER_OF_SYNTHESES = 1

        ! Set scalar symmetries
        if ( present( isym ) ) then

            call this%Set_scalar_symmetries( isym )

        end if

        ! Set vector symmetries
        if (present (itype) ) then

            call this%Set_vector_symmetries( itype )

        end if

        !--------------------------------------------------------------------------------
        ! Allocate array
        !--------------------------------------------------------------------------------

        associate( size_spec => nlat * (nlat + 1)/2 )

            ! Allocate pointer for complex spectral coefficients
            allocate ( &
                this%spec( 1:size_spec ), &
                stat = allocate_status, &
                errmsg = error_message )

            ! Check allocate status
            if ( allocate_status /= 0 ) then
                print *, 'Pointer allocation failed in '&
                    &'creation of sphere_t object: ', &
                    trim( error_message )
                return
            end if

        end associate

        !--------------------------------------------------------------------------------
        ! Create derived data types
        !--------------------------------------------------------------------------------

        ! Set grid and workspace
        if ( present( grid_type) ) then

            call this%grid%Create( nlat, nlon, grid_type )
            call this%workspace%Create( nlat, nlon, grid_type )

        else

            call this%grid%Create( nlat, nlon )
            call this%workspace%Create( nlat, nlon )

        end if

        !--------------------------------------------------------------------------------
        ! Set frequently used trigonometric functions
        !--------------------------------------------------------------------------------

        call this%Set_trigonometric_functions( &
            this%grid%latitudes, &
            this%grid%longitudes )

        !--------------------------------------------------------------------------------
        ! Set spherical unit vectors to compute polar and azimuthal components for vector functions
        !--------------------------------------------------------------------------------

        call this%Set_spherical_unit_vectors( &
            this%sint, &
            this%cost, &
            this%sinp, &
            this%cosp )

        !--------------------------------------------------------------------------------
        ! Set initialization flag
        !--------------------------------------------------------------------------------

        this%initialized = .true.
        
    end subroutine Create
    !
    !*****************************************************************************************
    !
    subroutine Destroy( this )
        !
        ! Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------

        !--------------------------------------------------------------------------------
        ! Check status
        !--------------------------------------------------------------------------------

        if ( .not. this%initialized ) return

        !--------------------------------------------------------------------------------
        ! Reset constants
        !--------------------------------------------------------------------------------

        this%NLON                = 0
        this%NLAT                = 0
        this%NTRUNC              = 0
        this%ISYM                = 0
        this%ITYPE               = 0
        this%NUMBER_OF_SYNTHESES = 0

        !--------------------------------------------------------------------------------
        ! Deallocate complex spectral coefficients
        !--------------------------------------------------------------------------------

        ! Check if array is allocated
        if ( allocated( this%spec ) ) then

            ! Deallocate array
            deallocate( &
                this%spec, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "spec" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        !--------------------------------------------------------------------------------
        ! Destroy derived data types
        !--------------------------------------------------------------------------------

        call this%grid%Destroy()
        call this%workspace%Destroy()

        !--------------------------------------------------------------------------------
        ! Deallocate trigonometric functions
        !--------------------------------------------------------------------------------

         ! Check if array is allocated
        if ( allocated( this%sint ) ) then

            ! Deallocate array
            deallocate( &
                this%sint, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "sint" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        ! Check if array is allocated
        if ( allocated( this%cost ) ) then

            ! Deallocate array
            deallocate( &
                this%cost, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "cost" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        ! Check if array is allocated
        if ( allocated( this%sinp ) ) then

            ! Deallocate array
            deallocate( &
                this%sinp, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "sinp" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        ! Check if array is allocated
        if ( allocated( this%cosp ) ) then

            ! Deallocate array
            deallocate( &
                this%cosp, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "cosp" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        !--------------------------------------------------------------------------------
        ! Deallocate spherical unit vectors
        !--------------------------------------------------------------------------------

        ! Check if array is allocated
        if ( allocated( this%radial_unit_vector ) ) then

            ! Deallocate array
            deallocate( &
                this%radial_unit_vector, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "radial_unit_vector" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        ! Check if array is allocated
        if ( allocated( this%polar_unit_vector ) ) then

            ! Deallocate array
            deallocate( &
                this%polar_unit_vector, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "polar_unit_vector" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if
        
        ! Check if array is allocated
        if ( allocated( this%azimuthal_unit_vector ) ) then

            ! Deallocate array
            deallocate( &
                this%azimuthal_unit_vector, &
                stat = deallocate_status, &
                errmsg = error_message )

            ! Check deallocation status
            if ( deallocate_status /= 0 ) then
                print *, 'Deallocating "azimuthal_unit_vector" failed in '&
                    &'destruction of sphere_t object: ', &
                    trim( error_message )
                stop
            end if

        end if

        !--------------------------------------------------------------------------------
        ! Reset initialization flag
        !--------------------------------------------------------------------------------

        this%initialized = .false.

    end subroutine Destroy
    !
    !*****************************************************************************************
    !
    subroutine Assert_initialized( this )
        !
        ! Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        !--------------------------------------------------------------------------------

        ! Check status
        if ( .not. this%initialized ) then
            error stop 'ERROR: You must instantiate type(sphere_t) before calling methods'
        end if

    end subroutine Assert_initialized
    !
    !*****************************************************************************************
    !
    function Get_index( this, n, m ) result( return_value )
        !
        ! Purpose:
        ! The spectral data is assumed to be in a complex array of dimension
        ! (MTRUNC+1)*(MTRUNC+2)/2. MTRUNC is the triangular truncation limit
        ! (MTRUNC = 42 for T42). MTRUNC must be <= nlat-1.
        !
        ! The coefficients are ordered so that
        !
        ! first (nm=1)  is m=0, n=0, second (nm=2) is m=0, n=1,
        ! nm=MTRUNC is m=0, n=MTRUNC, nm=MTRUNC+1 is m=1, n=1, etc.
        !
        ! In other words,
        !
        ! 00, 01, 02, 03, 04.........0MTRUNC
        !     11, 12, 13, 14.........1MTRUNC
        !         22, 23, 24.........2MTRUNC
        !             33, 34.........3MTRUNC
        !                 44.........4MTRUNC
        !                    .
        !                      .
        !                        .etc...
        !
        ! In modern Fortran syntax, values of m (degree) and n (order)
        ! as a function of the index nm are:
        !
        ! integer (IP), dimension ((MTRUNC+1)*(MTRUNC+2)/2) :: indxm, indxn
        ! indxm = [((m, n=m, MTRUNC), m=0, MTRUNC)]
        ! indxn = [((n, n=m, MTRUNC), m=0, MTRUNC)]
        !
        ! Conversely, the index nm as a function of m and n is:
        ! nm = sum([(i, i=MTRUNC+1, MTRUNC-m+2, -1)])+n-m+1
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        integer (IP)                       :: return_value
        class (sphere_t), intent (in out)  :: this
        integer (IP), intent (in)          :: n, m
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP) :: i !! Counter
        !--------------------------------------------------------------------------------

        ! Set constant
        associate( ntrunc => this%NTRUNC )

            if ( m <= n .and. max( n, m ) <= ntrunc ) then

                return_value = &
                    sum ( [ (i, i = ntrunc+1, ntrunc - m + 2, - 1) ] ) + n - m + 1
            else

                return_value = -1

            end if

        end associate

    end function Get_index
    !
    !*****************************************************************************************
    !
    function Get_coefficient( this, n, m ) result ( return_value )
        !
        ! Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)    :: this
        integer (IP), intent (in)            :: n, m
        complex (WP)                         :: return_value
        !--------------------------------------------------------------------------------

        associate( &
            ntrunc   => this%NTRUNC, &
            nm       => this%Get_index( n, m ), &
            nm_conjg => this%Get_index(n, -m ) &
            )

            if ( m < 0 .and. nm_conjg > 0 ) then

                return_value = &
                    ( (-1.0_WP)**(-m) ) * conjg( this%spec(nm_conjg) )

            else if ( nm > 0 ) then

                return_value = this%spec(nm)

            else

                return_value = 0.0_WP

            end if

        end associate

    end function Get_coefficient
    !
    !*****************************************************************************************
    !
    subroutine Set_scalar_symmetries( this, isym )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        integer (IP), intent (in)         :: isym
        !--------------------------------------------------------------------------------

        if ( isym == 2 ) then

            this%ISYM = isym

        else if ( isym == 1) then

            this%ISYM = isym

        else if ( isym == 0 ) then

            this%ISYM = isym

        else
            ! Handle invalid isym
            print *, 'ERROR: optional argument isym = ', isym
            print *, 'must be either 0, 1, or 2 (default isym = 0)'
            stop
        end if

    end subroutine Set_scalar_symmetries
        !
    !*****************************************************************************************
    !
    subroutine Set_vector_symmetries( this, itype )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        integer (IP), intent (in)         :: itype
        !--------------------------------------------------------------------------------

        if ( itype == 8 ) then

            this%itype = itype

        else if ( itype == 7) then

            this%itype = itype

        else if ( itype == 6) then

            this%itype = itype

        else if ( itype == 5) then

            this%itype = itype

        else if ( itype == 4) then

            this%itype = itype

        else if ( itype == 3) then

            this%itype = itype

        else if ( itype == 2) then

            this%itype = itype

        else if ( itype == 1) then

            this%itype = itype


        else if ( itype == 0 ) then

            this%itype = itype

        else
            ! Handle invalid isym
            print *, 'ERROR: optional argument itype = ', itype
            print *, 'must be either 0, 1, 2, ..., 8 (default itype = 0)'
            stop

        end if

    end subroutine Set_vector_symmetries
    !
    !*****************************************************************************************
    !
    subroutine Set_trigonometric_functions( this, theta, phi )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)       :: this
        real (WP), dimension (:), intent (in)   :: theta, phi
        !--------------------------------------------------------------------------------

        ! Check if latitudes are allocated
        if ( .not. allocated( this%grid%latitudes ) ) then

            print *, 'ERROR: You must allocate "latitudes" '&
                &//'before calling "Set_trigonometric_functions"'
            stop

        ! Check if longitudes are allocated
        else if ( .not. allocated( this%grid%longitudes ) ) then

            print *, 'ERROR: You must allocate "longitudes" '&
                &//'before calling "Set_trigonometric_functions"'
            stop

        end if

        associate( &
            nlat => size( theta ), &
            nlon => size( phi ) &
            )
            ! Allocate arrays
            allocate ( &
                this%sint( 1:nlat ), &
                this%cost( 1:nlat ), &
                this%sinp( 1:nlon ), &
                this%cosp( 1:nlon ), &
                stat = allocate_status, &
                errmsg = error_message )

            ! Check allocation status
            if ( allocate_status /= 0 ) then
                print *, 'Allocation failed in '&
                    &'Set_trigonometric_functions: ', &
                    trim( error_message )
                stop
            end if

        end associate

        ! Compute trigonometric functions
        this%sint = sin( theta )
        this%cost = cos( theta )
        this%sinp = sin( phi )
        this%cosp = cos( phi )

    end subroutine Set_trigonometric_functions
    !
    !*****************************************************************************************
    !
    subroutine Set_spherical_unit_vectors( this, sint, cost, sinp, cosp )
        !
        ! Purpose:
        ! Sets the spherical unit vectors
        !
        ! Remark:
        ! The "grid" component of sphere must be
        ! initialized before calling this subroutine
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)      :: this
        real (WP), dimension (:), intent (in)  :: sint, cost, sinp, cosp
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)  ::  k, l !! Counters
        !--------------------------------------------------------------------------------

        dimensions: associate( &
            nlat => this%NLAT, &
            nlon => this%NLON &
            )

            ! Allocate arrays
            allocate ( &
                this%radial_unit_vector( 1:3, 1:nlat, 1:nlon ), &
                this%polar_unit_vector( 1:3, 1:nlat, 1:nlon ), &
                this%azimuthal_unit_vector( 1:3, 1:nlat, 1:nlon ), &
                stat = allocate_status, &
                errmsg = error_message )

            ! Check allocate status
            if ( allocate_status /= 0 ) then
                print *, 'Allocation failed in '&
                    &'Set_spherical_unit_vectors: ', &
                    trim( error_message )
                return
            end if

            unit_vectors: associate( &
                r     => this%radial_unit_vector, &
                theta => this%polar_unit_vector, &
                phi   => this%azimuthal_unit_vector &
                )

                ! Compute spherical unit vectors
                do l = 1, nlon
                    do k = 1, nlat

                        ! set radial unit vector
                        r(:, k, l) = &
                            [ sint(k) * cosp(l), &
                            sint(k) * sinp(l), &
                            cost(k) ]

                        ! set polar unit vector
                        theta(:, k, l) = &
                            [ cost(k) * cosp(l), &
                            cost(k) * sinp(l), &
                            -sint(k) ]

                        ! set azimuthal unit vector
                        phi(:, k, l) = &
                            [ -sinp(l), &
                            cosp(l), &
                            0.0_WP ]
                    end do
                end do

            end associate unit_vectors

        end associate dimensions

    end subroutine Set_spherical_unit_vectors
    !
    !*****************************************************************************************
    !
    subroutine Perform_complex_analysis( this, scalar_function )
        !
        ! Purpose:
        ! converts gridded input array (scalar_function) to (complex) spherical harmonic coefficients
        ! (dataspec).
        !
        ! the spectral data is assumed to be in a complex array of dimension
        ! (mtrunc+1)*(mtrunc+2)/2. mtrunc is the triangular truncation limit
        ! (mtrunc = 42 for t42). mtrunc must be <= nlat-1. coefficients are
        ! ordered so that first (nm=1) is m=0, n=0, second is m=0, n=1,
        ! nm=mtrunc is m=0, n=mtrunc, nm=mtrunc+1 is m=1, n=1, etc.
        ! in fortran95 syntax, values of m (degree) and n (order) as a function
        ! of the index nm are:

        ! integer (IP), dimension ((mtrunc+1)*(mtrunc+2)/2) :: indxm, indxn
        ! indxm = [((m, n=m, mtrunc), m=0, mtrunc)]
        ! indxn = [((n, n=m, mtrunc), m=0, mtrunc)]

        ! conversely, the index nm as a function of m and n is:
        ! nm = sum([(i, i=mtrunc+1, mtrunc-m+2, -1)])+n-m+1
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (in)  :: scalar_function
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP) :: m,  n  !< counters
        !--------------------------------------------------------------------------------
        
        ! Check status
        call this%Assert_initialized()
        
        ! compute the (real) spherical harmonic coefficients
        call this%Perform_scalar_analysis( scalar_function )

        associate( &
            ntrunc => this%NTRUNC, & ! set the triangular truncation limit
            a      => this%workspace%a, &
            b      => this%workspace%b &
            )

            ! fill complex array dataspec with result
            this%spec = &
                cmplx( &
                0.5_WP * [((a(m + 1, n + 1), n = m, ntrunc), m = 0, ntrunc)], &
                0.5_WP * [((b(m + 1, n + 1), n = m, ntrunc), m = 0, ntrunc)], &
                WP )
 
        end associate

    end subroutine Perform_complex_analysis
    !
    !*****************************************************************************************
    !
    subroutine Perform_complex_synthesis( this, scalar_function )
        !
        ! Purpose:
        ! converts gridded input array (datagrid) to (complex) spherical harmonic coefficients
        ! (dataspec).
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)         :: this
        real (WP), dimension (:, :), intent (out)  :: scalar_function
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP) :: m, n  !! Counters
        integer (IP) :: nm    !! Index
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        associate( &
            ntrunc => this%NTRUNC, & ! set the triangular truncation limit
            a      => this%workspace%a, &
            b      => this%workspace%b &
            )
 
            ! Fill real arrays with contents of spec
            do m = 0, ntrunc
                do n = m, ntrunc
                
                    ! set the spectral index
                    nm = this%Get_index( n, m )
                
                    ! set the real component
                    a( m + 1, n + 1 ) = 2.0_WP * real( this%spec(nm) )
                
                    ! set the imaginary component
                    b( m + 1, n + 1 ) = 2.0_WP * aimag( this%spec(nm) )
                
                end do
            end do
        
        end associate

        ! synthesise the scalar function from the (real) harmonic coeffiients
        call this%Perform_scalar_synthesis( scalar_function )
 
    end subroutine Perform_complex_synthesis
    !
    !*****************************************************************************************
    !
    subroutine Synthesize_from_spec( this, spec, scalar_function )
        !
        ! Purpose:
        ! used mainly for testing the spectral method module
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        complex (WP), dimension (:), intent (in)   :: spec
        real (WP), dimension (:, :), intent (out)   :: scalar_function
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: m, n     !! Counters
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        associate( &
            ntrunc => this%NTRUNC, & ! set the triangular truncation limit
            a      => this%workspace%a, &
            b      => this%workspace%b &
            )
 
            ! fill real arrays with contents of spec
            do m = 0, ntrunc
                do n = m, ntrunc
                
                    ! set the spectral index
                    spec_index: associate( nm => this%Get_index( n, m ) )
                
                        ! set the real component
                        a(m + 1, n + 1) = 2.0_WP * real( spec(nm) )
                
                        ! set the imaginary component
                        b(m + 1, n + 1) = 2.0_WP * aimag( spec(nm) )

                    end associate spec_index

                end do
            end do
        
        end associate

        ! synthesise the scalar function from the (real) harmonic coeffiients
        call this%Perform_scalar_synthesis( scalar_function )
 
    end subroutine Synthesize_from_spec
    !
    !*****************************************************************************************
    !
    subroutine Get_spherical_angle_components( this, &
        vector_function, polar_component, azimuthal_component )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        real (WP), dimension (:, :, :), intent (in)  :: vector_function
        real (WP), dimension (:, :), intent (out)   :: polar_component
        real (WP), dimension (:, :), intent (out)   :: azimuthal_component
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)    :: k,  l        !! Counters
        type (vector_t) :: theta, phi   !! Spherical unit vectors
        type (vector_t) :: vector_field
        !--------------------------------------------------------------------------------
        
        ! Check status
        call this%Assert_initialized()
        
        ! initialize arrays
        polar_component = 0.0_WP
        azimuthal_component = 0.0_WP
        
        associate( &
            nlat => this%NLAT, &
            nlon => this%NLON &
            )

            ! calculate the spherical angle components
            do l = 1, nlon
                do k = 1, nlat
                
                    ! set the vector function
                    vector_field = vector_function(:, k, l)

                    ! set the latitudinal spherical unit vector
                    theta = this%polar_unit_vector(:, k, l)

                    ! set the longitudinal spherical unit vector
                    phi = this%azimuthal_unit_vector(:, k, l)

                    ! set the theta component
                    polar_component(k, l) = &
                        theta.dot.vector_field
               
                    ! set the azimuthal_component
                    azimuthal_component(k, l) = &
                        phi.dot.vector_field

                end do
            end do

        end associate

    end subroutine Get_spherical_angle_components
    !
    !*****************************************************************************************
    !
    subroutine Get_rotation_operator( this, scalar_function, rotation_operator)
        !
        ! Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        real (WP), dimension (:, :), intent (in)    :: scalar_function
        real (WP), dimension (:, :, :), intent (out) :: rotation_operator
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)                            :: k, l         !! Counters
        type (vector_t)                         :: theta,  phi
        real (WP), dimension (:, :), allocatable :: polar_gradient_component
        real (WP), dimension (:, :), allocatable :: azimuthal_gradient_component
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! Set constants
        associate( &
            nlat => this%NLAT, &
            nlon => this%NLON &
            )

            ! Allocate arrays
            allocate ( &
                polar_gradient_component( 1:nlat, 1:nlon ), &
                azimuthal_gradient_component( 1:nlat, 1:nlon ), &
                stat = allocate_status, &
                errmsg = error_message )

            ! Check allocation status
            if ( allocate_status /= 0 ) then
                print *, 'Allocation failed '&
                    &//'in "Get_rotation_operator":', &
                    trim( error_message )
                return
            end if

            ! calculate the spherical surface gradient components
            call this%Get_gradient( &
                scalar_function, &
                polar_gradient_component, azimuthal_gradient_component)

            ! initialize array
            rotation_operator = 0.0_WP

            ! calculate the rotation operator applied to a scalar function
            do l = 1, nlon
                do k = 1, nlat

                    ! set the theta spherical unit vector
                    theta = this%polar_unit_vector(:, k, l)

                    ! set the phi spherical unit vector
                    phi = this%azimuthal_unit_vector(:, k, l)

                    rotation_operator(:, k, l) = &
                        phi * polar_gradient_component(k, l) &
                        - theta * azimuthal_gradient_component(k, l)
                end do

            end do

        end associate

        ! Deallocate arrays
        deallocate ( &
            polar_gradient_component, &
            azimuthal_gradient_component, &
            stat = deallocate_status, &
            errmsg = error_message )

        ! Check deallocate status
        if ( deallocate_status /= 0 ) then
            print *, 'Deallocation failed '&
                &//'in "Get_rotation_operator":', &
                trim( error_message )
            return
        end if

    end subroutine Get_rotation_operator
    !
    !*****************************************************************************************
    !
    function Compute_surface_integral( this, scalar_function ) result( return_value )
        !
        ! Purpose:
        ! computes the surface integral on the sphere (trapezoidal rule in phi
        ! and gaussian quadrature in theta)
        !
        !   \int_{s^1} sf(theta, phi) ds
        !
        !    for ds : = ds(theta, phi) = sin(theta) dtheta dphi
        !
        !    for 0 <= theta <= pi and 0 <= phi <= 2*pi
        !
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (in)  :: scalar_function
        real (WP)                                :: return_value
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)                     :: k         !! counter
        real (WP), dimension (this%NLAT) :: integrant !! integrant
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! Initialize array
        integrant = 0.0_WP

        ! Compute the integrant
        associate( &
            nlat => this%NLAT, &
            Dphi => this%grid%mesh_phi, &
            wts  => this%grid%gaussian_weights, &
            f    => scalar_function &
            )

            do k = 1, nlat

                integrant(k) = sum( f(k, :) ) * Dphi

            end do

            integrant = integrant * wts

        end associate

        return_value = sum( integrant )

    end function Compute_surface_integral
    !
    !*****************************************************************************************
    !
    subroutine Compute_first_moment( this, scalar_function, first_moment )
        !
        ! Purpose:
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (in)  :: scalar_function
        type (vector_t), intent (out)            :: first_moment
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)                                   :: k,  l
        type (vector_t)                                :: u
        real (WP), dimension (this%NLAT, this%NLON, 3) :: integrant
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        associate( &
            nlat => this%NLAT, &
            nlon => this%NLON, &
            f    => scalar_function &
            )

            ! Initialize array
            integrant = 0.0_WP

            ! Compute integrant
            do l = 1, nlon
                do k = 1, nlat

                    u = this%radial_unit_vector(:, k, l)

                    integrant(k, l, 1) = u%x * f(k, l)
                    integrant(k, l, 2) = u%y * f(k, l)
                    integrant(k, l, 3) = u%z * f(k, l)

                end do
            end do

        end associate

        ! set first moment
        first_moment%x = &
            this%Compute_surface_integral( integrant(:, :, 1))

        first_moment%y = &
            this%Compute_surface_integral( integrant(:, :, 2))

        first_moment%z = &
            this%Compute_surface_integral( integrant(:, :, 3))

    end subroutine Compute_first_moment
    !
    !*****************************************************************************************
    !
    ! Public SPHEREPACK 3.2 methods
    !
    !*****************************************************************************************
    !
    subroutine Get_colatitude_derivative( this, polar_component, azimuthal_component )
        !
        ! Purpose:
        !
        ! Reference:
        ! https://www2.cisl.ucar.edu/spherepack/documentation#vtsgs.html
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (out) :: polar_component     !! vt
        real (WP), dimension (:, :), intent (out) :: azimuthal_component !! wt
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        !        ! TODO incorporate Vtsgsi into type(workspace)
        !        subroutine vtsgsi(nlat, nlon, wvts, lwvts, work, lwork, dwork, ldwork, ierror)

        !        call Vtsgs( &
        !            size( this%grid%latitudes ), size( this%grid%longitudes ),  this%ityp, 1, &
        !            polar_component, azimuthal_component, &
        !            this%NLAT, this%NLON, &
        !            this%workspace%br, this%workspace%bi, &
        !            this%workspace%cr, this%workspace%ci, &
        !            size(this%workspace%br, dim = 1), size(this%workspace%br, dim = 2), &
        !            this%workspace%wvts, this%workspace%size(wvts), &
        !            this%workspace%work, size(this%workspace%work), ierror)

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Get_colatitude_derivative
    !
    !*****************************************************************************************
    !
    subroutine Get_gradient( this, scalar_function, &
        polar_gradient_component, &
        azimuthal_gradient_component )
        !
        ! SPHEREPACK 3.2 documentation
        !
        !     subroutine gradgs(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab,
        !                    wvhsgs, lvhsgs, work, lwork, ierror)
        !
        !     given the scalar spherical harmonic coefficients a and b, precomputed
        !     by subroutine shags for a scalar field sf, subroutine gradgs computes
        !     an irrotational vector field (v, w) such that
        !
        !           gradient(sf) = (v, w).
        !
        !     v is the colatitudinal and w is the east longitudinal component
        !     of the gradient.  i.e.,
        !
        !            v(i, j) = d(sf(i, j))/dtheta
        !
        !     and
        !
        !            w(i, j) = 1/sint*d(sf(i, j))/dlambda
        !
        !     at the gaussian colatitude point theta(i) (see nlat as input
        !     parameter) and longitude lambda(j) = (j-1)*2*pi/nlon where
        !     sint = sin(theta(i)).
        !
        !
        !     input parameters
        !
        !     nlat   the number of points in the gaussian colatitude grid on the
        !            full sphere. these lie in the interval (0, pi) and are computed
        !            in radians in theta(1) <...< theta(nlat) by subroutine gaqd.
        !            if nlat is odd the equator will be included as the grid point
        !            theta((nlat+1)/2).  if nlat is even the equator will be
        !            excluded as a grid point and will lie half way between
        !            theta(nlat/2) and theta(nlat/2+1). nlat must be at least 3.
        !            note: on the half sphere, the number of grid points in the
        !            colatitudinal direction is nlat/2 if nlat is even or
        !            (nlat+1)/2 if nlat is odd.
        !
        !     nlon   the number of distinct londitude points.  nlon determines
        !            the grid increment in longitude as 2*pi/nlon. for example
        !            nlon = 72 for a five degree grid. nlon must be greater than
        !            3.  the efficiency of the computation is improved when nlon
        !            is a product of small prime numbers.
        !
        !
        !     isym   this has the same value as the isym that was input to
        !            subroutine shags to compute the arrays a and b from the
        !            scalar field sf.  isym determines whether (v, w) are
        !            computed on the full or half sphere as follows:
        !
        !      = 0
        !
        !           sf is not symmetric about the equator. in this case
        !           the vector field (v, w) is computed on the entire sphere.
        !           i.e., in the arrays  v(i, j), w(i, j) for i=1, ..., nlat and
        !           j=1, ..., nlon.
        !
        !      = 1
        !
        !           sf is antisymmetric about the equator. in this case w is
        !           antisymmetric and v is symmetric about the equator. w
        !           and v are computed on the northern hemisphere only.  i.e.,
        !           if nlat is odd they are computed for i=1, ..., (nlat+1)/2
        !           and j=1, ..., nlon.  if nlat is even they are computed for
        !           i=1, ..., nlat/2 and j=1, ..., nlon.
        !
        !      = 2
        !
        !           sf is symmetric about the equator. in this case w is
        !           symmetric and v is antisymmetric about the equator. w
        !           and v are computed on the northern hemisphere only.  i.e.,
        !           if nlat is odd they are computed for i=1, ..., (nlat+1)/2
        !           and j=1, ..., nlon.  if nlat is even they are computed for
        !           i=1, ..., nlat/2 and j=1, ..., nlon.
        !
        !
        !     nt     nt is the number of scalar and vector fields.  some
        !            computational efficiency is obtained for multiple fields.
        !            the arrays a, b, v, and w can be three dimensional corresponding
        !            to an indexed multiple array sf.  in this case, multiple
        !            vector synthesis will be performed to compute each vector
        !            field.  the third index for a, b, v, and w is the synthesis
        !            index which assumes the values k = 1, ..., nt.  for a single
        !            synthesis set nt = 1.  the description of the remaining
        !            parameters is simplified by assuming that nt=1 or that a, b, v,
        !            and w are two dimensional arrays.
        !
        !     idvw   the first dimension of the arrays v, w as it appears in
        !            the program that calls gradgs. if isym = 0 then idvw
        !            must be at least nlat.  if isym = 1 or 2 and nlat is
        !            even then idvw must be at least nlat/2. if isym = 1 or 2
        !            and nlat is odd then idvw must be at least (nlat+1)/2.
        !
        !     jdvw   the second dimension of the arrays v, w as it appears in
        !            the program that calls gradgs. jdvw must be at least nlon.
        !
        !     a, b    two or three dimensional arrays (see input parameter nt)
        !            that contain scalar spherical harmonic coefficients
        !            of the scalar field array sf as computed by subroutine shags.
        !     ***    a, b must be computed by shags prior to calling gradgs.
        !
        !     mdab   the first dimension of the arrays a and b as it appears in
        !            the program that calls gradgs (and shags). mdab must be at
        !            least min0(nlat, (nlon+2)/2) if nlon is even or at least
        !            min0(nlat, (nlon+1)/2) if nlon is odd.
        !
        !     ndab   the second dimension of the arrays a and b as it appears in
        !            the program that calls gradgs (and shags). ndab must be at
        !            least nlat.
        !
        !
        !     wvhsgs an array which must be initialized by subroutine vhsgsi.
        !            once initialized,
        !            wvhsgs can be used repeatedly by gradgs as long as nlon
        !            and nlat remain unchanged.  wvhsgs must not be altered
        !            between calls of gradgs.
        !
        !
        !     lvhsgs the dimension of the array wvhsgs as it appears in the
        !            program that calls grradgs.  define
        !
        !               l1 = min0(nlat, nlon/2) if nlon is even or
        !               l1 = min0(nlat, (nlon+1)/2) if nlon is odd
        !
        !            and
        !
        !               l2 = nlat/2        if nlat is even or
        !               l2 = (nlat+1)/2    if nlat is odd
        !
        !            then lvhsgs must be at least
        !
        !                 l1*l2*(nlat+nlat-l1+1)+nlon+15+2*nlat
        !
        !
        !     work   a work array that does not have to be saved.
        !
        !     lwork  the dimension of the array work as it appears in the
        !            program that calls gradgs. define
        !
        !               l1 = min0(nlat, nlon/2) if nlon is even or
        !               l1 = min0(nlat, (nlon+1)/2) if nlon is odd
        !
        !            and
        !
        !               l2 = nlat/2                  if nlat is even or
        !               l2 = (nlat+1)/2              if nlat is odd
        !
        !            if isym = 0, lwork must be greater than or equal to
        !
        !               nlat*((2*nt+1)*nlon+2*l1*nt+1).
        !
        !            if isym = 1 or 2, lwork must be greater than or equal to
        !
        !               (2*nt+1)*l2*nlon+nlat*(2*l1*nt+1).
        !
        !
        !     **************************************************************
        !
        !     output parameters
        !
        !
        !     v, w   two or three dimensional arrays (see input parameter nt) that
        !           contain an irrotational vector field such that the gradient of
        !           the scalar field sf is (v, w).  w(i, j) is the east longitude
        !           component and v(i, j) is the colatitudinal component of velocity
        !           at gaussian colatitude and longitude lambda(j) = (j-1)*2*pi/nlon
        !           the indices for v and w are defined at the input parameter
        !           isym.  the vorticity of (v, w) is zero.  note that any nonzero
        !           vector field on the sphere will be multiple valued at the poles
        !           [reference swarztrauber].
        !
        !
        !  ierror   = 0  no errors
        !           = 1  error in the specification of nlat
        !           = 2  error in the specification of nlon
        !           = 3  error in the specification of isym
        !           = 4  error in the specification of nt
        !           = 5  error in the specification of idvw
        !           = 6  error in the specification of jdvw
        !           = 7  error in the specification of mdab
        !           = 8  error in the specification of ndab
        !           = 9  error in the specification of lvhsgs
        !           = 10 error in the specification of lwork
        !
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (in)  :: scalar_function
        real (WP), dimension (:, :), intent (out) :: polar_gradient_component
        real (WP), dimension (:, :), intent (out) :: azimuthal_gradient_component
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: error_flag
        !--------------------------------------------------------------------------------
        
        ! Check status
        call this%Assert_initialized()

        ! compute the (real) harmonic coefficients
        call this%Perform_scalar_analysis( scalar_function )

        associate( &
            nlat   => this%NLAT, &
            nlon   => this%NLON, &
            isym   => this%ISYM, &
            nt     => this%NUMBER_OF_SYNTHESES, &
            v      =>  polar_gradient_component, &
            w      => azimuthal_gradient_component, &
            idvw   => this%NLAT, &
            jdvw   => this%NLON, &
            a      => this%workspace%a, &
            b      => this%workspace%b, &
            mdab   => this%NLAT, &
            ndab   => this%NLAT, &
            wvhsgs => this%workspace%wvhsgs, &
            lvhsgs => size( this%workspace%wvhsgs ), &
            work   => this%workspace%work, &
            lwork  => size( this%workspace%work ), &
            ierror => error_flag &
            )

            call Gradgs( nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab, &
                wvhsgs, lvhsgs, work, lwork, ierror)

        end associate

        ! Check error flag
        if ( error_flag  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', error_flag, ' in Gradgs'
            stop
        end if

    end subroutine Get_gradient
    !
    !*****************************************************************************************
    !
    subroutine Invert_gradient( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Invert_gradient
    !
    !*****************************************************************************************
    !
    subroutine Get_divergence( this, vector_field, divergence )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        real (WP), dimension (:, :, :), intent (in)  :: vector_field
        real (WP), dimension (:, :), intent (out)   :: divergence
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! calculate the (real) vector harmonic coefficients
        call this%Perform_vector_analysis( vector_field )

        ! calculate the surface divergence
        call Divgs( &
            this%NLAT, this%NLON, &
            this%ISYM, 1, divergence, this%NLAT, this%NLON, &
            this%workspace%br, this%workspace%bi, &
            this%NLAT, this%NLAT, &
            this%workspace%wshsgs, size( this%workspace%wshsgs ), &
            this%workspace%work, size( this%workspace%work ), ierror)

        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, 'in Divgs'
            return
        end if

    end subroutine Get_divergence
    !
    !*****************************************************************************************
    !
    subroutine Invert_divergence( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Invert_divergence
    !
    !*****************************************************************************************
    !
    subroutine Get_vorticity( this, vector_field, vorticity )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        real (WP), dimension (:, :, :), intent (in)  :: vector_field
        real (WP), dimension (:, :), intent (out)   :: vorticity
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! calculate the (real) vector harmonic coefficients
        call this%Perform_vector_analysis( vector_field )

        ! calculate the surface vorticity
        call Vrtgs( &
            this%NLAT,  &
            this%NLON, &
            this%ISYM, 1, vorticity, &
            this%NLAT, this%NLON, &
            this%workspace%cr, this%workspace%ci, &
            this%NLAT, this%NLON, &
            this%workspace%wshsgs, size( this%workspace%wshsgs ), &
            this%workspace%work, size( this%workspace%work ), ierror)

        ! check the error flag
        if (ierror  /=  0)  then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vrtgs'
            return
        end if

    end subroutine Get_vorticity
    !
    !*****************************************************************************************
    !
    subroutine Invert_vorticity( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Invert_vorticity
    !
    !*****************************************************************************************
    !
    subroutine Invert_divergence_and_vorticity( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Invert_divergence_and_vorticity
    !
    !*****************************************************************************************
    !
    subroutine Get_scalar_laplacian( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Get_scalar_laplacian
    !
    !*****************************************************************************************
    !
    subroutine Invert_helmholtz( this, helmholtz_constant, source_term, solution )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)         :: this
        real (WP), intent (in)                    :: helmholtz_constant
        real (WP), dimension (:, :), intent (in)   :: source_term
        real (WP), dimension (:, :), intent (out)  :: solution
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        real (WP)     :: perturbation
        integer (IP)  :: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        call this%Perform_scalar_analysis( source_term )

        ! invert the helmholtz (or poisson) equation
        !
        ! see: https://www2.cisl.ucar.edu/spherepack/documentation#islapgs.html
        call Islapgs( &
            this%NLAT, this%NLON, &
            this%ISYM, 1, helmholtz_constant, &
            solution, this%NLAT, this%NLON, &
            this%workspace%a, this%workspace%b, &
            this%NLAT, this%NLAT, &
            this%workspace%wshsgs, size( this%workspace%wshsgs ), &
            this%workspace%work, size( this%workspace%work ), &
            perturbation, ierror)

        ! check for errors
        if ( ierror /= 0 ) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Islapgs'
            return
        end if

    end subroutine Invert_helmholtz
    !
    !*****************************************************************************************
    !
    subroutine Get_vector_laplacian( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Get_vector_laplacian
    !
    !*****************************************************************************************
    !
    subroutine Invert_vector_laplacian( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Invert_vector_laplacian
    !
    !*****************************************************************************************
    !
    subroutine Get_stream_function_and_velocity_potential( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Get_stream_function_and_velocity_potential
    !
    !*****************************************************************************************
    !
    subroutine Invert_stream_function_and_velocity_potential( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Invert_stream_function_and_velocity_potential
    !
    !*****************************************************************************************
    !
    subroutine Perform_grid_transfers( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Perform_grid_transfers
    !
    !*****************************************************************************************
    !
    subroutine Perform_geo_math_coordinate_transfers( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Perform_geo_math_coordinate_transfers
    !
    !*****************************************************************************************
    !
    subroutine Perform_scalar_analysis( this, scalar_function )
        !
        ! Reference:
        ! https://www2.cisl.ucar.edu/spherepack/documentation#shags.html
        !
        ! SPHEREPACK 3.2 documentation
        !
        !     subroutine shags(nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, &
        !                      wshags, lshags, work, lwork, ierror)
        !
        !     subroutine shags performs the spherical harmonic analysis
        !     on the array g and stores the result in the arrays a and b.
        !     the analysis is performed on a gaussian grid in colatitude
        !     and an equally spaced grid in longitude.  the associated
        !     legendre functions are stored rather than recomputed as they
        !     are in subroutine shagc.  the analysis is described below
        !     at output parameters a, b.
        !
        !     input parameters
        !
        !     nlat   the number of points in the gaussian colatitude grid on the
        !            full sphere. these lie in the interval (0, pi) and are compu
        !            in radians in theta(1), ..., theta(nlat) by subroutine gaqd.
        !            if nlat is odd the equator will be included as the grid poi
        !            theta((nlat+1)/2).  if nlat is even the equator will be
        !            excluded as a grid point and will lie half way between
        !            theta(nlat/2) and theta(nlat/2+1). nlat must be at least 3.
        !            note: on the half sphere, the number of grid points in the
        !            colatitudinal direction is nlat/2 if nlat is even or
        !            (nlat+1)/2 if nlat is odd.
        !
        !     nlon   the number of distinct londitude points.  nlon determines
        !            the grid increment in longitude as 2*pi/nlon. for example
        !            nlon = 72 for a five degree grid. nlon must be greater
        !            than or equal to 4. the efficiency of the computation is
        !            improved when nlon is a product of small prime numbers.
        !
        !     isym   = 0  no symmetries exist about the equator. the analysis
        !                 is performed on the entire sphere.  i.e. on the
        !                 array g(i, j) for i=1, ..., nlat and j=1, ..., nlon.
        !                 (see description of g below)
        !
        !            = 1  g is antisymmetric about the equator. the analysis
        !                 is performed on the northern hemisphere only.  i.e.
        !                 if nlat is odd the analysis is performed on the
        !                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
        !                 if nlat is even the analysis is performed on the
        !                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
        !
        !
        !            = 2  g is symmetric about the equator. the analysis is
        !                 performed on the northern hemisphere only.  i.e.
        !                 if nlat is odd the analysis is performed on the
        !                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
        !                 if nlat is even the analysis is performed on the
        !                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
        !
        !     nt     the number of analyses.  in the program that calls shags,
        !            the arrays g, a and b can be three dimensional in which
        !            case multiple analyses will be performed.  the third
        !            index is the analysis index which assumes the values
        !            k=1, ..., nt.  for a single analysis set nt=1. the
        !            discription of the remaining parameters is simplified
        !            by assuming that nt=1 or that the arrays g, a and b
        !            have only two dimensions.
        !
        !     g      a two or three dimensional array (see input parameter
        !            nt) that contains the discrete function to be analyzed.
        !            g(i, j) contains the value of the function at the gaussian
        !            point theta(i) and longitude point phi(j) = (j-1)*2*pi/nlon
        !            the index ranges are defined above at the input parameter
        !            isym.
        !
        !     idg    the first dimension of the array g as it appears in the
        !            program that calls shags. if isym equals zero then idg
        !            must be at least nlat.  if isym is nonzero then idg must
        !            be at least nlat/2 if nlat is even or at least (nlat+1)/2
        !            if nlat is odd.
        !
        !     jdg    the second dimension of the array g as it appears in the
        !            program that calls shags. jdg must be at least nlon.
        !
        !     mdab   the first dimension of the arrays a and b as it appears
        !            in the program that calls shags. mdab must be at least
        !            min0((nlon+2)/2, nlat) if nlon is even or at least
        !            min0((nlon+1)/2, nlat) if nlon is odd.
        !
        !     ndab   the second dimension of the arrays a and b as it appears
        !            in the program that calls shags. ndab must be at least nlat
        !
        !     wshags an array which must be initialized by subroutine shagsi.
        !            once initialized, wshags can be used repeatedly by shags
        !            as long as nlat and nlon remain unchanged.  wshags must
        !            not be altered between calls of shags.
        !
        !     lshags the dimension of the array wshags as it appears in the
        !            program that calls shags. define
        !
        !               l1 = min0(nlat, (nlon+2)/2) if nlon is even or
        !               l1 = min0(nlat, (nlon+1)/2) if nlon is odd
        !
        !            and
        !
        !               l2 = nlat/2        if nlat is even or
        !               l2 = (nlat+1)/2    if nlat is odd
        !
        !            then lshags must be at least
        !
        !            nlat*(3*(l1+l2)-2)+(l1-1)*(l2*(2*nlat-l1)-3*l1)/2+nlon+15
        !
        !     work   a real work space which need not be saved
        !
        !
        !     lwork  the dimension of the array work as it appears in the
        !            program that calls shags. define
        !
        !               l2 = nlat/2        if nlat is even or
        !               l2 = (nlat+1)/2    if nlat is odd
        !
        !
        !            if isym is zero then lwork must be at least
        !
        !                  nlat*nlon*(nt+1)
        !
        !            if isym is nonzero then lwork must be at least
        !
        !                  l2*nlon*(nt+1)
        !
        !     **************************************************************
        !
        !     output parameters
        !
        !     a, b    both a, b are two or three dimensional arrays (see input
        !            parameter nt) that contain the spherical harmonic
        !            coefficients in the representation of g(i, j) given in the
        !            discription of subroutine shags. for isym=0, a(m, n) and
        !            b(m, n) are given by the equations listed below. symmetric
        !            versions are used when isym is greater than zero.
        !
        !     definitions
        !
        !     1. the normalized associated legendre functions
        !
        !     pbar(m, n, theta) = sqrt((2*n+1)*factorial(n-m)/(2*factorial(n+m)))
        !                       *sin(theta)**m/(2**n*factorial(n)) times the
        !                       (n+m)th derivative of (x**2-1)**n with respect
        !                       to x=cos(theta).
        !
        !     2. the fourier transform of g(i, j).
        !
        !     c(m, i)          = 2/nlon times the sum from j=1 to j=nlon of
        !                       g(i, j)*cos((m-1)*(j-1)*2*pi/nlon)
        !                       (the first and last terms in this sum
        !                       are divided by 2)
        !
        !     s(m, i)          = 2/nlon times the sum from j=2 to j=nlon of
        !                       g(i, j)*sin((m-1)*(j-1)*2*pi/nlon)
        !
        !
        !     3. the gaussian points and weights on the sphere
        !        (computed by subroutine gaqd).
        !
        !        theta(1), ..., theta(nlat) (gaussian pts in radians)
        !        wts(1), ..., wts(nlat) (corresponding gaussian weights)
        !
        !
        !     4. the maximum (plus one) longitudinal wave number
        !
        !            mmax = min0(nlat, (nlon+2)/2) if nlon is even or
        !            mmax = min0(nlat, (nlon+1)/2) if nlon is odd.
        !
        !
        !     then for m=0, ..., mmax-1 and n=m, ..., nlat-1 the arrays a, b
        !     are given by
        !
        !     a(m+1, n+1)     =  the sum from i=1 to i=nlat of
        !                       c(m+1, i)*wts(i)*pbar(m, n, theta(i))
        !
        !     b(m+1, n+1)      = the sum from i=1 to nlat of
        !                       s(m+1, i)*wts(i)*pbar(m, n, theta(i))
        !
        !     ierror = 0  no errors
        !            = 1  error in the specification of nlat
        !            = 2  error in the specification of nlon
        !            = 3  error in the specification of isym
        !            = 4  error in the specification of nt
        !            = 5  error in the specification of idg
        !            = 6  error in the specification of jdg
        !            = 7  error in the specification of mdab
        !            = 8  error in the specification of ndab
        !            = 9  error in the specification of lshags
        !            = 10 error in the specification of lwork
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)         :: this
        real (WP), dimension (:, :), intent (in)  :: scalar_function
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: error_flag
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! perform the (real) spherical harmonic analysis
        associate( &
            nlat   => this%NLAT, &
            nlon   => this%NLON, &
            isym   => this%ISYM, &
            nt     => this%NUMBER_OF_SYNTHESES, &
            g      => scalar_function, &
            idg    => this%NLAT, &
            jdg    => this%NLON, &
            a      => this%workspace%a, &
            b      => this%workspace%b, &
            mdab   => this%NLAT, &
            ndab   => this%NLAT, &
            wshags => this%workspace%wshags, &
            lshags => size( this%workspace%wshags ), &
            work   => this%workspace%work, &
            lwork  => size( this%workspace%work ), &
            ierror => error_flag &
            )

            call Shags( nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, &
                wshags, lshags, work, lwork, ierror )

        end associate

        ! check the error status
        if ( error_flag /= 0 ) then
            print *, 'SPHEREPACK 3.2 error = ', error_flag, ' in Shags'
            return
        end if

    end subroutine Perform_scalar_analysis
    !
    !*****************************************************************************************
    !
    subroutine Perform_scalar_synthesis( this, scalar_function )
        !
        ! Reference:
        ! https://www2.cisl.ucar.edu/spherepack/documentation#shsgs.html
        !
        ! SPHEREPACK 3.2 documentation
        !     subroutine shsgs(nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, &
        !                        wshsgs, lshsgs, work, lwork, ierror)
        !
        !     subroutine shsgs performs the spherical harmonic synthesis
        !     on the arrays a and b and stores the result in the array g.
        !     the synthesis is performed on an equally spaced longitude grid
        !     and a gaussian colatitude grid.  the associated legendre functions
        !     are stored rather than recomputed as they are in subroutine
        !     shsgc.  the synthesis is described below at output parameter
        !     g.
        !
        !
        !     input parameters
        !
        !     nlat   the number of points in the gaussian colatitude grid on the
        !            full sphere. these lie in the interval (0, pi) and are compu
        !            in radians in theta(1), ..., theta(nlat) by subroutine gaqd.
        !            if nlat is odd the equator will be included as the grid poi
        !            theta((nlat+1)/2).  if nlat is even the equator will be
        !            excluded as a grid point and will lie half way between
        !            theta(nlat/2) and theta(nlat/2+1). nlat must be at least 3.
        !            note: on the half sphere, the number of grid points in the
        !            colatitudinal direction is nlat/2 if nlat is even or
        !            (nlat+1)/2 if nlat is odd.
        !
        !     nlon   the number of distinct londitude points.  nlon determines
        !            the grid increment in longitude as 2*pi/nlon. for example
        !            nlon = 72 for a five degree grid. nlon must be greater
        !            than or equal to 4. the efficiency of the computation is
        !            improved when nlon is a product of small prime numbers.
        !
        !     isym   = 0  no symmetries exist about the equator. the synthesis
        !                 is performed on the entire sphere.  i.e. on the
        !                 array g(i, j) for i=1, ..., nlat and j=1, ..., nlon.
        !                 (see description of g below)
        !
        !            = 1  g is antisymmetric about the equator. the synthesis
        !                 is performed on the northern hemisphere only.  i.e.
        !                 if nlat is odd the synthesis is performed on the
        !                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
        !                 if nlat is even the synthesis is performed on the
        !                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
        !
        !
        !            = 2  g is symmetric about the equator. the synthesis is
        !                 performed on the northern hemisphere only.  i.e.
        !                 if nlat is odd the synthesis is performed on the
        !                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
        !                 if nlat is even the synthesis is performed on the
        !                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
        !
        !     nt     the number of syntheses.  in the program that calls shsgs,
        !            the arrays g, a and b can be three dimensional in which
        !            case multiple synthesis will be performed.  the third
        !            index is the synthesis index which assumes the values
        !            k=1, ..., nt.  for a single synthesis set nt=1. the
        !            discription of the remaining parameters is simplified
        !            by assuming that nt=1 or that the arrays g, a and b
        !            have only two dimensions.
        !
        !     idg    the first dimension of the array g as it appears in the
        !            program that calls shagc. if isym equals zero then idg
        !            must be at least nlat.  if isym is nonzero then idg must
        !            be at least nlat/2 if nlat is even or at least (nlat+1)/2
        !            if nlat is odd.
        !
        !     jdg    the second dimension of the array g as it appears in the
        !            program that calls shagc. jdg must be at least nlon.
        !
        !     a, b    two or three dimensional arrays (see the input parameter
        !            nt) that contain the coefficients in the spherical harmonic
        !            expansion of g(i, j) given below at the definition of the
        !            output parameter g.  a(m, n) and b(m, n) are defined for
        !            indices m=1, ..., mmax and n=m, ..., nlat where mmax is the
        !            maximum (plus one) longitudinal wave number given by
        !            mmax = min0(nlat, (nlon+2)/2) if nlon is even or
        !            mmax = min0(nlat, (nlon+1)/2) if nlon is odd.
        !
        !     mdab   the first dimension of the arrays a and b as it appears
        !            in the program that calls shsgs. mdab must be at least
        !            min0((nlon+2)/2, nlat) if nlon is even or at least
        !            min0((nlon+1)/2, nlat) if nlon is odd.
        !
        !     ndab   the second dimension of the arrays a and b as it appears
        !            in the program that calls shsgs. ndab must be at least nlat
        !
        !     wshsgs an array which must be initialized by subroutine shsgsi.
        !            once initialized, wshsgs can be used repeatedly by shsgs
        !            as long as nlat and nlon remain unchanged.  wshsgs must
        !            not be altered between calls of shsgs.
        !
        !     lshsgs the dimension of the array wshsgs as it appears in the
        !            program that calls shsgs. define
        !
        !               l1 = min0(nlat, (nlon+2)/2) if nlon is even or
        !               l1 = min0(nlat, (nlon+1)/2) if nlon is odd
        !
        !            and
        !
        !               l2 = nlat/2        if nlat is even or
        !               l2 = (nlat+1)/2    if nlat is odd
        !
        !            then lshsgs must be at least
        !
        !            nlat*(3*(l1+l2)-2)+(l1-1)*(l2*(2*nlat-l1)-3*l1)/2+nlon+15
        !
        !
        !     lwork  the dimension of the array work as it appears in the
        !            program that calls shsgs. define
        !
        !               l2 = nlat/2        if nlat is even or
        !               l2 = (nlat+1)/2    if nlat is odd
        !
        !
        !            if isym is zero then lwork must be at least
        !
        !                  nlat*nlon*(nt+1)
        !
        !            if isym is nonzero then lwork must be at least
        !
        !                  l2*nlon*(nt+1)
        !
        !
        !     **************************************************************
        !
        !     output parameters
        !
        !     g      a two or three dimensional array (see input parameter nt)
        !            that contains the discrete function which is synthesized.
        !            g(i, j) contains the value of the function at the gaussian
        !            colatitude point theta(i) and longitude point
        !            phi(j) = (j-1)*2*pi/nlon. the index ranges are defined
        !            above at the input parameter isym.  for isym=0, g(i, j)
        !            is given by the the equations listed below.  symmetric
        !            versions are used when isym is greater than zero.
        !
        !     the normalized associated legendre functions are given by
        !
        !     pbar(m, n, theta) = sqrt((2*n+1)*factorial(n-m)/(2*factorial(n+m)))
        !                       *sin(theta)**m/(2**n*factorial(n)) times the
        !                       (n+m)th derivative of (x**2-1)**n with respect
        !                       to x=cos(theta)
        !
        !     define the maximum (plus one) longitudinal wave number
        !     as   mmax = min0(nlat, (nlon+2)/2) if nlon is even or
        !          mmax = min0(nlat, (nlon+1)/2) if nlon is odd.
        !
        !     then g(i, j) = the sum from n=0 to n=nlat-1 of
        !
        !                   .5*pbar(0, n, theta(i))*a(1, n+1)
        !
        !              plus the sum from m=1 to m=mmax-1 of
        !
        !                   the sum from n=m to n=nlat-1 of
        !
        !              pbar(m, n, theta(i))*(a(m+1, n+1)*cos(m*phi(j))
        !                                    -b(m+1, n+1)*sin(m*phi(j)))
        !
        !
        !     ierror = 0  no errors
        !            = 1  error in the specification of nlat
        !            = 2  error in the specification of nlon
        !            = 3  error in the specification of isym
        !            = 4  error in the specification of nt
        !            = 5  error in the specification of idg
        !            = 6  error in the specification of jdg
        !            = 7  error in the specification of mdab
        !            = 8  error in the specification of ndab
        !            = 9  error in the specification of lshsgs
        !            = 10 error in the specification of lwork
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        real (WP), dimension (:, :), intent (out)  :: scalar_function
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: error_flag
        !--------------------------------------------------------------------------------

        ! perform (real) spherical harmonic synthesis
        associate( &
            nlat   => this%NLAT, &
            nlon   => this%NLON, &
            isym   => this%ISYM, &
            nt     => this%NUMBER_OF_SYNTHESES, &
            g      => scalar_function, &
            idg    => size( scalar_function, dim = 1), &
            jdg    => size( scalar_function, dim = 2), &
            a      => this%workspace%a, &
            b      => this%workspace%b, &
            mdab   => this%NLAT, &
            ndab   => this%NLAT, &
            wshsgs => this%workspace%wshsgs, &
            lshsgs => size( this%workspace%wshsgs ), &
            work   => this%workspace%work, &
            lwork  => size( this%workspace%work ), &
            ierror => error_flag &
            )

            call Shsgs( nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, &
                wshsgs, lshsgs, work, lwork, ierror )

        end associate

        ! check the error status
        if ( error_flag /= 0 ) then
            print *, 'SPHEREPACK 3.2 error = ', error_flag, ' in Shsgs'
            return
        end if

    end subroutine Perform_scalar_synthesis
    !
    !*****************************************************************************************
    !
    subroutine Perform_scalar_projection( this, scalar_function, scalar_projection )
        !
        ! Purpose:
        !
        ! Reference:
        ! https://www2.cisl.ucar.edu/spherepack/documentation#shpg.html
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (in)  :: scalar_function
        real (WP), dimension (:, :), intent (out) :: scalar_projection
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! TODO: Include driver program into type(workspace)
        !        call Shpgi( &
        !            this%NLAT, this%NLON, this%ISYM, this%NTRUNC, &
        !            this%workspace%wshp, size( this%workspace%wshp ), &
        !            this%workspace%iwshp, size( this%workspace%iwshp ), &
        !            this%workspace%work, size( this%workspace%work ), ierror )
        !
        !        call Shpg( &
        !            this%NLAT, this%NLON, this%ISYM, this%NTRUNC, &
        !            scalar_function, scalar_projection, this%NLAT, &
        !            this%workspace%wshp, size( this%workspace%wshp ), &
        !            this%workspace%iwshp, size( this%workspace%iwshp ), &
        !            this%workspace%work, size( this%workspace%work ), ierror )

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Perform_scalar_projection
    !
    !*****************************************************************************************
    !
    subroutine Perform_vector_analysis( this, vector_function )
        !
        ! Purpose:
        ! converts gridded input array (datagrid) to real spectral coefficients
        ! (dataspec).
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)          :: this
        real (WP), dimension (:, :, :), intent (in)  :: vector_function
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP)                            :: nlat
        integer (IP)                            :: nlon
        integer (IP)                            :: ierror
        real (WP), dimension (:, :), allocatable :: polar_component
        real (WP), dimension (:, :), allocatable :: azimuthal_component
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! Set contants
        nlat = this%NLAT
        nlon = this%NLON

        ! Allocate arrays
        allocate ( &
            polar_component( 1:nlat, 1:nlon), &
            azimuthal_component( 1:nlat, 1:nlon), &
            stat = allocate_status )
        if ( allocate_status /= 0 ) then
            print *, "Allocation failed!"
            return
        end if

        ! compute the spherical angle components
        call this%Get_spherical_angle_components( &
            vector_function, &
            polar_component, &
            azimuthal_component)

        ! calculate (real) vector spherical harmonic analysis
        call Vhags( nlat, nlon, &
            this%ISYM, 1, polar_component, &
            azimuthal_component, &
            nlat, nlon, this%workspace%br, this%workspace%bi, &
            this%workspace%cr, this%workspace%ci, nlat, nlat, &
            this%workspace%wvhags, size( this%workspace%wvhags ), &
            this%workspace%work, size( this%workspace%work ), ierror)

        ! check the error status
        if ( ierror /= 0 ) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vhags'
            return
        end if

        ! Deallocate arrays
        deallocate ( &
            polar_component, &
            azimuthal_component, &
            stat = deallocate_status )
        if ( deallocate_status /= 0 ) then
            print *, 'Deallocation failed in '&
                &//'Perform_vector_analysis'
            return
        end if

    end subroutine Perform_vector_analysis
    !
    !*****************************************************************************************
    !
    subroutine Perform_vector_synthesis( this, polar_component, azimuthal_component )
        ! Purpose:
        ! converts gridded input array (datagrid) to real spectral coefficients
        ! (dataspec).
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)        :: this
        real (WP), dimension (:, :), intent (out) :: polar_component
        real (WP), dimension (:, :), intent (out) :: azimuthal_component
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ! resynthesise the components from the (real) vector coefficients
        call Vhsgs( &
            this%NLAT, this%NLON, &
            this%ISYM, 1, &
            polar_component, &
            azimuthal_component, &
            this%NLAT, this%NLON, &
            this%workspace%br, this%workspace%bi, &
            this%workspace%cr, this%workspace%ci, &
            this%NLAT, this%NLAT, &
            this%workspace%wvhsgs, size( this%workspace%wvhsgs ), &
            this%workspace%work, size( this%workspace%work ), ierror)

        ! check the error status
        if ( ierror /= 0 ) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vhsgs'
            return
        end if

    end subroutine Perform_vector_synthesis
    !
    !*****************************************************************************************
    !
    subroutine Get_legendre_functions( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Get_legendre_functions
    !
    !*****************************************************************************************
    !
    subroutine Icosahedral_geodesic( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Icosahedral_geodesic
    !
    !*****************************************************************************************
    !
    subroutine Perform_multiple_ffts( this )
        !
        ! Purpose:
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------
        ! Dictionary: local variables
        !--------------------------------------------------------------------------------
        integer (IP):: ierror
        !--------------------------------------------------------------------------------

        ! Check status
        call this%Assert_initialized()

        ierror = 0
        ! check the error flag
        if (ierror  /=  0) then
            print *, 'SPHEREPACK 3.2 error = ', ierror, ' in Vtsgs'
            return
        end if

    end subroutine Perform_multiple_ffts
    !
    !*****************************************************************************************
    !
    subroutine Get_gaussian_weights_and_points( this, nlat, theta, wts )
        !
        ! Purpose:
        !
        ! Computes the nlat-many gaussian (co)latitudes and weights.
        ! the colatitudes are in radians and lie in the interval (0, pi).
        !
        ! References:
        !
        ! [1] Swarztrauber, Paul N.
        !     "On computing the points and weights for Gauss--Legendre quadrature."
        !     SIAM Journal on Scientific Computing 24.3 (2003): 945-954.

        ! [2]  http://www2.cisl.ucar.edu/spherepack/documentation#gaqd.html
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        class (sphere_t), intent (in out)     :: this
        integer (IP), intent (in)             :: nlat  !! number of latitudinal points
        real (WP), dimension (:), allocatable :: theta !! latitudinal points: 0 <= theta <= pi
        real (WP), dimension (:), allocatable :: wts   !! gaussian weights
        !--------------------------------------------------------------------------------

        call this%grid%Get_gaussian_weights_and_points( nlat, theta, wts )

    end subroutine Get_gaussian_weights_and_points
    !
    !*****************************************************************************************
    !
    subroutine Finalize( this )
        !
        ! Purpose:
        !< Finalize object
        !
        !--------------------------------------------------------------------------------
        ! Dictionary: calling arguments
        !--------------------------------------------------------------------------------
        type (sphere_t), intent (in out) :: this
        !--------------------------------------------------------------------------------

        call this%Destroy()

    end subroutine Finalize
    !
    !*****************************************************************************************
    !
end module type_sphere_mod
