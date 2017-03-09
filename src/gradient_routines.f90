module gradient_routines

    use spherepack_precision, only: &
        wp, & ! working precision
        ip ! integer precision

    use scalar_synthesis_routines, only: &
        shsec, shses, shsgc, shsgs

    use vector_synthesis_routines, only: &
        vhses, vhsec, vhsgc, vhsgs

    ! Explicit typing only
    implicit none

    ! Everything is private unless stated otherwise
    private
    public :: gradec, grades, gradgc, gradgs
    public :: igradec, igrades, igradgc, igradgs
    public :: perform_setup_for_inversion
    public :: perform_setup_for_gradient

    ! Parameters confined to the module
    real(wp), parameter :: ZERO = 0.0_wp
    real(wp), parameter :: ONE = 1.0_wp

        ! Declare interfaces for submodule implementation
    interface
        module subroutine gradec(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab, &
            wvhsec, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: v(idvw, jdvw, nt)
            real(wp),    intent(out) :: w(idvw, jdvw, nt)
            integer(ip), intent(in)  :: idvw
            integer(ip), intent(in)  :: jdvw
            real(wp),    intent(in)  :: a(mdab, ndab, nt)
            real(wp),    intent(in)  :: b(mdab, ndab, nt)
            integer(ip), intent(in)  :: mdab
            integer(ip), intent(in)  :: ndab
            real(wp),    intent(in)  :: wvhsec(:)
            integer(ip), intent(out) :: ierror
        end subroutine gradec

        module subroutine grades(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab, &
            wvhses, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: v(idvw, jdvw, nt)
            real(wp),    intent(out) :: w(idvw, jdvw, nt)
            integer(ip), intent(in)  :: idvw
            integer(ip), intent(in)  :: jdvw
            real(wp),    intent(in)  :: a(mdab, ndab, nt)
            real(wp),    intent(in)  :: b(mdab, ndab, nt)
            integer(ip), intent(in)  :: mdab
            integer(ip), intent(in)  :: ndab
            real(wp),    intent(in)  :: wvhses(:)
            integer(ip), intent(out) :: ierror
        end subroutine grades

        module subroutine gradgc(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab, &
            wvhsgc, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: v(idvw, jdvw, nt)
            real(wp),    intent(out) :: w(idvw, jdvw, nt)
            integer(ip), intent(in)  :: idvw
            integer(ip), intent(in)  :: jdvw
            real(wp),    intent(in)  :: a(mdab, ndab, nt)
            real(wp),    intent(in)  :: b(mdab, ndab, nt)
            integer(ip), intent(in)  :: mdab
            integer(ip), intent(in)  :: ndab
            real(wp),    intent(in)  :: wvhsgc(:)
            integer(ip), intent(out) :: ierror
        end subroutine gradgc

        module subroutine gradgs(nlat, nlon, isym, nt, v, w, idvw, jdvw, a, b, mdab, ndab, &
            wvhsgs, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: v(idvw, jdvw, nt)
            real(wp),    intent(out) :: w(idvw, jdvw, nt)
            integer(ip), intent(in)  :: idvw
            integer(ip), intent(in)  :: jdvw
            real(wp),    intent(in)  :: a(mdab, ndab, nt)
            real(wp),    intent(in)  :: b(mdab, ndab, nt)
            integer(ip), intent(in)  :: mdab
            integer(ip), intent(in)  :: ndab
            real(wp),    intent(in)  :: wvhsgs(:)
            integer(ip), intent(out) :: ierror
        end subroutine gradgs

        module subroutine igradec(nlat, nlon, isym, nt, sf, isf, jsf, br, bi, mdb, ndb, &
            wshsec, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: sf(isf, jsf, nt)
            integer(ip), intent(in)  :: isf
            integer(ip), intent(in)  :: jsf
            real(wp),    intent(in)  :: br(mdb, ndb, nt)
            real(wp),    intent(in)  :: bi(mdb, ndb, nt)
            integer(ip), intent(in)  :: mdb
            integer(ip), intent(in)  :: ndb
            real(wp),    intent(in)  :: wshsec(:)
            integer(ip), intent(out) :: ierror
        end subroutine igradec

        module subroutine igrades(nlat, nlon, isym, nt, sf, isf, jsf, br, bi, mdb, ndb, &
            wshses, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: sf(isf, jsf, nt)
            integer(ip), intent(in)  :: isf
            integer(ip), intent(in)  :: jsf
            real(wp),    intent(in)  :: br(mdb, ndb, nt)
            real(wp),    intent(in)  :: bi(mdb, ndb, nt)
            integer(ip), intent(in)  :: mdb
            integer(ip), intent(in)  :: ndb
            real(wp),    intent(in)  :: wshses(:)
            integer(ip), intent(out) :: ierror
        end subroutine igrades

        module subroutine igradgc(nlat, nlon, isym, nt, sf, isf, jsf, br, bi, mdb, ndb, &
            wshsgc, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: sf(isf, jsf, nt)
            integer(ip), intent(in)  :: isf
            integer(ip), intent(in)  :: jsf
            real(wp),    intent(in)  :: br(mdb, ndb, nt)
            real(wp),    intent(in)  :: bi(mdb, ndb, nt)
            integer(ip), intent(in)  :: mdb
            integer(ip), intent(in)  :: ndb
            real(wp),    intent(in)  :: wshsgc(:)
            integer(ip), intent(out) :: ierror
        end subroutine igradgc

        module subroutine igradgs(nlat, nlon, isym, nt, sf, isf, jsf, br, bi, mdb, ndb, &
            wshsgs, ierror)

            ! Dummy arguments
            integer(ip), intent(in)  :: nlat
            integer(ip), intent(in)  :: nlon
            integer(ip), intent(in)  :: isym
            integer(ip), intent(in)  :: nt
            real(wp),    intent(out) :: sf(isf, jsf, nt)
            integer(ip), intent(in)  :: isf
            integer(ip), intent(in)  :: jsf
            real(wp),    intent(in)  :: br(mdb, ndb, nt)
            real(wp),    intent(in)  :: bi(mdb, ndb, nt)
            integer(ip), intent(in)  :: mdb
            integer(ip), intent(in)  :: ndb
            real(wp),    intent(in)  :: wshsgs(:)
            integer(ip), intent(out) :: ierror
        end subroutine igradgs
    end interface

contains

    pure subroutine compute_coefficient_multipliers(sqnn)

        ! Dummy arguments
        real(wp), intent(out) :: sqnn(:)

        ! Local variables
        integer(ip) :: n

        sqnn = [(sqrt(real(n - 1, kind=wp) * (real(n - 1, kind=wp) + ONE)), n=1, size(sqnn))]

    end subroutine compute_coefficient_multipliers

    pure subroutine perform_setup_for_gradient(isym, ityp, a, b, br, bi, sqnn)

        ! Dummy arguments
        integer(ip), intent(in)  :: isym
        integer(ip), intent(out) :: ityp
        real(wp),    intent(in)  :: a(:, :, :)
        real(wp),    intent(in)  :: b(:, :, :)
        real(wp),    intent(out) :: br(:, :, :)
        real(wp),    intent(out) :: bi(:, :, :)
        real(wp),    intent(out) :: sqnn(:)

        ! Local variables
        integer(ip) :: k, n, m

        associate (&
            mmax => size(br, dim=1), &
            nlat => size(br, dim=2), &
            nt => size(br, dim=3) &
            )

            ! Preset coefficient multiplyers in vector
            call compute_coefficient_multipliers(sqnn)

            ! Compute multiple vector fields coefficients
            do k=1, nt
                br(:, :, k) = ZERO
                bi(:, :, k) = ZERO

                ! Compute m = 0 coefficients
                do n=2, nlat
                    br(1, n, k) = sqnn(n) * a(1, n, k)
                    bi(1, n, k) = sqnn(n) * b(1, n, k)
                end do

                ! Compute m > 0 coefficients
                do m=2, mmax
                    do n=m, nlat
                        br(m, n, k) = sqnn(n) * a(m, n, k)
                        bi(m, n, k) = sqnn(n) * b(m, n, k)
                    end do
                end do
            end do

            ! Set ityp for irrotational vector synthesis to compute gradient
            select case (isym)
                case (0)
                    ityp = 1
                case (1)
                    ityp = 4
                case (2)
                    ityp = 7
            end select
        end associate

    end subroutine perform_setup_for_gradient

    pure subroutine perform_setup_for_inversion(nlon, a, b, br, bi, sqnn)

        ! Dummy arguments
        integer(ip), intent(in)  :: nlon
        real(wp),    intent(out) :: a(:, :, :)
        real(wp),    intent(out) :: b(:, :, :)
        real(wp),    intent(in)  :: br(:, :, :)
        real(wp),    intent(in)  :: bi(:, :, :)
        real(wp),    intent(out) :: sqnn(:)

        ! Local variables
        integer(ip) :: k, n, m, mmax

        associate (&
            nlat => size(a, dim=2), &
            nt => size(a, dim=3) &
            )

            ! Preset coefficient multiplyers in vector
            call compute_coefficient_multipliers(sqnn)

            ! Set upper limit for vector m subscript
            mmax = min(nlat, (nlon+1)/2)

            ! Preset to 0.0
            a = ZERO
            b = ZERO

            ! Compute multiple scalar field coefficients
            do k=1, nt

                ! Compute m=0 coefficients
                do n=2, nlat
                    a(1, n, k) = br(1, n, k)/sqnn(n)
                    b(1, n, k)= bi(1, n, k)/sqnn(n)
                end do

                ! Compute m > 0 coefficients
                do m=2, mmax
                    do n=m, nlat
                        a(m, n, k) = br(m, n, k)/sqnn(n)
                        b(m, n, k) = bi(m, n, k)/sqnn(n)
                    end do
                end do
            end do
        end associate

    end subroutine perform_setup_for_inversion

end module gradient_routines
