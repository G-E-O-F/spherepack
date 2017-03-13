!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 1998 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                      SPHEREPACK                               *
!     *                                                               *
!     *       A Package of Fortran Subroutines and Programs           *
!     *                                                               *
!     *              for Modeling Geophysical Processes               *
!     *                                                               *
!     *                             by                                *
!     *                                                               *
!     *                  John Adams and Paul Swarztrauber             *
!     *                                                               *
!     *                             of                                *
!     *                                                               *
!     *         the National Center for Atmospheric Research          *
!     *                                                               *
!     *                Boulder, Colorado  (80307)  U.S.A.             *
!     *                                                               *
!     *                   which is sponsored by                       *
!     *                                                               *
!     *              the National Science Foundation                  *
!     *                                                               *
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!
submodule(scalar_synthesis_routines) scalar_synthesis_gaussian_grid

contains

    ! Purpose:
    !
    ! This subroutine performs the spherical harmonic synthesis on
    ! a gaussian grid using the coefficients in array(s) a, b and returns
    ! the results in array(s) g.  the legendre polynomials are computed
    ! as needed in this version.
    !
    !     subroutine shsgc(nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, &
    !                      wshsgc, ierror)
    !
    !     subroutine shsgc performs the spherical harmonic synthesis
    !     on the arrays a and b and stores the result in the array g.
    !     the synthesis is performed on an equally spaced longitude grid
    !     and a gaussian colatitude grid.  the associated legendre functions
    !     are recomputed rather than stored as they are in subroutine
    !     shsgs.  the synthesis is described below at output parameter
    !     g.
    !
    !     input parameters
    !
    !     nlat   the number of points in the gaussian colatitude grid on the
    !            full sphere. these lie in the interval (0, pi) and are compu
    !            in radians in theta(1), ..., theta(nlat) by subroutine compute_gaussian_latitudes_and_weights.
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
    !     nt     the number of syntheses.  in the program that calls shsgc,
    !            the arrays g, a and b can be three dimensional in which
    !            case multiple synthesis will be performed.  the third
    !            index is the synthesis index which assumes the values
    !            k=1, ..., nt.  for a single synthesis set nt=1. the
    !            discription of the remaining parameters is simplified
    !            by assuming that nt=1 or that the arrays g, a and b
    !            have only two dimensions.
    !
    !     idg    the first dimension of the array g as it appears in the
    !            program that calls shsgc. if isym equals zero then idg
    !            must be at least nlat.  if isym is nonzero then idg must
    !            be at least nlat/2 if nlat is even or at least (nlat+1)/2
    !            if nlat is odd.
    !
    !     jdg    the second dimension of the array g as it appears in the
    !            program that calls shsgc. jdg must be at least nlon.
    !
    !     mdab   the first dimension of the arrays a and b as it appears
    !            in the program that calls shsgc. mdab must be at least
    !            min((nlon+2)/2, nlat) if nlon is even or at least
    !            min((nlon+1)/2, nlat) if nlon is odd
    !
    !     ndab   the second dimension of the arrays a and b as it appears
    !            in the program that calls shsgc. ndab must be at least nlat
    !
    !     a, b    two or three dimensional arrays (see the input parameter
    !            nt) that contain the coefficients in the spherical harmonic
    !            expansion of g(i, j) given below at the definition of the
    !            output parameter g.  a(m, n) and b(m, n) are defined for
    !            indices m=1, ..., mmax and n=m, ..., nlat where mmax is the
    !            maximum (plus one) longitudinal wave number given by
    !            mmax = min(nlat, (nlon+2)/2) if nlon is even or
    !            mmax = min(nlat, (nlon+1)/2) if nlon is odd.
    !
    !     wshsgc an array which must be initialized by subroutine shsgci.
    !            once initialized, wshsgc can be used repeatedly by shsgc
    !            as long as nlat and nlon remain unchanged.  wshsgc must
    !            not be altered between calls of shsgc.
    !
    !     lshsgc the dimension of the array wshsgc as it appears in the
    !            program that calls shsgc. define
    !
    !               l1 = min(nlat, (nlon+2)/2) if nlon is even or
    !               l1 = min(nlat, (nlon+1)/2) if nlon is odd
    !
    !            and
    !
    !               l2 = nlat/2        if nlat is even or
    !               l2 = (nlat+1)/2    if nlat is odd
    !
    !            then lshsgc must be at least
    !
    !               nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15
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
    !
    !     define the maximum (plus one) longitudinal wave number
    !     as   mmax = min(nlat, (nlon+2)/2) if nlon is even or
    !          mmax = min(nlat, (nlon+1)/2) if nlon is odd.
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
    !     ierror = 0  no errors
    !            = 1  error in the specification of nlat
    !            = 2  error in the specification of nlon
    !            = 3  error in the specification of isym
    !            = 4  error in the specification of nt
    !            = 5  error in the specification of idg
    !            = 6  error in the specification of jdg
    !            = 7  error in the specification of mdab
    !            = 8  error in the specification of ndab
    !            = 9  error in the specification of lshsgc
    !
    module subroutine shsgc(nlat, nlon, mode, nt, g, idg, jdg, a, b, mdab, ndab, &
        wshsgc, ierror)

        ! Dummy arguments
        integer(ip), intent(in)  :: nlat
        integer(ip), intent(in)  :: nlon
        integer(ip), intent(in)  :: mode
        integer(ip), intent(in)  :: nt
        real(wp),    intent(out) :: g(idg, jdg, nt)
        integer(ip), intent(in)  :: idg
        integer(ip), intent(in)  :: jdg
        real(wp),    intent(in)  :: a(mdab, ndab, nt)
        real(wp),    intent(in)  :: b(mdab, ndab, nt)
        integer(ip), intent(in)  :: mdab
        integer(ip), intent(in)  :: ndab
        real(wp),    intent(in)  :: wshsgc(:)
        integer(ip), intent(out) :: ierror

        ! Local variables
        integer(ip) :: mtrunc, l1, l2, lat, late, lwork

        associate (lshsgc => size(wshsgc))

            ! Set limit for m in a(m, n), b(m, n) computation
            mtrunc = min((nlon+2)/2, nlat)

            ! Set gaussian point nearest equator pointer
            late = (nlat+mod(nlat, 2))/2

            ! Set number of grid points for analysis/synthesis
            select case (mode)
                case (0)
                    lat = nlat
                case default
                    lat = late
            end select

            l1 = mtrunc
            l2 = late

            ! Check calling arguments
            if (nlat < 3) then
                ierror = 1
            else if (nlon < 4) then
                ierror = 2
            else if (mode < 0 .or. mode > 2) then
                ierror = 3
            else if (nt < 1) then
                ierror = 4
            else if (idg < lat) then
                ierror = 5
            else if (jdg < nlon) then
                ierror = 6
            else if (mdab < mtrunc) then
                ierror = 7
            else if (ndab < nlat) then
                ierror = 8
            else if (lshsgc < nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15) then
                ierror = 9
            else
                ierror = 0
            end if

            ! Check error flag
            if (ierror /= 0) return

            ! Set required workspace size
            select case (mode)
                case (0)
                    lwork = nlat * (nlon * nt + max(3*l2, nlon))
                case default
                    lwork = l2 * (nlon * nt + max(3*nlat, nlon))
            end select

            block
                real(wp)    :: work(lwork)
                integer(ip) :: ipmn, ifft

                ! Starting address  fft values
                ifft = nlat+2*nlat*late+3*(mtrunc*(mtrunc-1)/2+(nlat-mtrunc)*(mtrunc-1))+1

                ! Set pointers for internal storage of g and legendre polys
                ipmn = lat*nlon*nt+1

                call shsgc_lower_utility_routine(nlat, nlon, mtrunc, lat, mode, g, idg, &
                    jdg, nt, a, b, mdab, ndab, wshsgc, wshsgc(ifft:), late, work(ipmn:), work)
            end block
        end associate

    end subroutine shsgc

    ! Purpose:
    !
    ! This subroutine must be called before calling shsgc with
    ! fixed nlat, nlon. it precomputes quantites such as the gaussian
    ! points and weights, m=0, m=1 legendre polynomials, recursion
    ! recursion coefficients.
    !
    !     subroutine shsgci(nlat, nlon, wshsgc, ierror)
    !
    !     subroutine shsgci initializes the array wshsgc which can then
    !     be used repeatedly by subroutines shsgc. it precomputes
    !     and stores in wshsgc quantities such as gaussian weights,
    !     legendre polynomial coefficients, and fft trigonometric tables.
    !
    !     input parameters
    !
    !     nlat   the number of points in the gaussian colatitude grid on the
    !            full sphere. these lie in the interval (0, pi) and are compu
    !            in radians in theta(1), ..., theta(nlat) by subroutine compute_gaussian_latitudes_and_weights.
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
    !     wshsgc an array which must be initialized by subroutine shsgci.
    !            once initialized, wshsgc can be used repeatedly by shsgc
    !            as long as nlat and nlon remain unchanged.  wshsgc must
    !            not be altered between calls of shsgc.
    !
    !     lshsgc the dimension of the array wshsgc as it appears in the
    !            program that calls shsgc. define
    !
    !               l1 = min(nlat, (nlon+2)/2) if nlon is even or
    !               l1 = min(nlat, (nlon+1)/2) if nlon is odd
    !
    !            and
    !
    !               l2 = nlat/2        if nlat is even or
    !               l2 = (nlat+1)/2    if nlat is odd
    !
    !            then lshsgc must be at least
    !
    !                  nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15
    !
    !     output parameter
    !
    !     wshsgc an array which must be initialized before calling shsgc.
    !            once initialized, wshsgc can be used repeatedly by shsgc
    !            as long as nlat and nlon remain unchanged.  wshsgc must not
    !            altered between calls of shsgc.
    !
    !     ierror = 0  no errors
    !            = 1  error in the specification of nlat
    !            = 2  error in the specification of nlon
    !            = 3  error in the specification of lshsgc
    !            = 5  failure in compute_gaussian_latitudes_and_weights to compute gaussian points
    !                 (due to failure in eigenvalue routine)
    !
    !
    module subroutine shsgci(nlat, nlon, wshsgc, ierror)

        ! Dummy arguments
        integer(ip), intent(in)  :: nlat
        integer(ip), intent(in)  :: nlon
        real(wp),    intent(out) :: wshsgc(:)
        integer(ip), intent(out) :: ierror

        ! Local variables
        integer(ip) :: i1
        integer(ip) :: i2
        integer(ip) :: i3
        integer(ip) :: i4
        integer(ip) :: i5
        integer(ip) :: i6
        integer(ip) :: i7
        integer(ip) :: idth
        integer(ip) :: idwts
        integer(ip) :: iw
        integer(ip) :: ntrunc
        integer(ip) :: l1
        integer(ip) :: l2
        integer(ip) :: late, ldwork

        associate (lshsgc => size(wshsgc))

            ! Set triangular truncation limit for spherical harmonic basis
            ntrunc = min((nlon+2)/2, nlat)

            ! Set equator or nearest point (if excluded) pointer
            late = (nlat+mod(nlat, 2))/2
            l1 = ntrunc
            l2 = late

            ! Check calling arguments
            if (nlat < 3) then
                ierror = 1
            else if (nlon < 4) then
                ierror = 2
            else if (lshsgc < nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15) then
                ierror = 3
            else
                ierror = 0
            end if

            ! Check error flag
            if (ierror /= 0) return

            ! Set index pointers
            i1 = 1
            i2 = i1+nlat
            i3 = i2+nlat*late
            i4 = i3+nlat*late
            i5 = i4+ntrunc*(ntrunc-1)/2 +(nlat-ntrunc)*(ntrunc-1)
            i6 = i5+ntrunc*(ntrunc-1)/2 +(nlat-ntrunc)*(ntrunc-1)
            i7 = i6+ntrunc*(ntrunc-1)/2 +(nlat-ntrunc)*(ntrunc-1)

            ! Set indices in temp work for real gaussian wts and pts
            idth = 1
            idwts = idth + nlat
            iw = idwts + nlat

            ! Set required workspace size
            ldwork = nlat * (nlat + 4)

            block
                real(wp) :: dwork(ldwork)
                call shsgci_lower_utility_routine(nlat, nlon, ntrunc, late, wshsgc(i1:), &
                    wshsgc(i2:), wshsgc(i3:), wshsgc(i4:), wshsgc(i5:), wshsgc(i6:), &
                    wshsgc(i7:), dwork(idth:), dwork(idwts:), dwork(iw:), ierror)
            end block

            ! Check error flag from lower utility routine
            if (ierror /= 0) ierror = 5
        end associate

    end subroutine shsgci

    subroutine shsgc_lower_utility_routine(nlat, nlon, l, lat, mode, gs, idg, jdg, nt, a, b, mdab, &
        ndab, w, wfft, late, pmn, g)

        real(wp) :: a
        real(wp) :: b
        real(wp) :: g
        real(wp) :: gs
        integer(ip) :: i
        integer(ip) :: idg
        integer(ip) :: is
        integer(ip) :: j
        integer(ip) :: jdg
        integer(ip) :: k
        integer(ip) :: km
        integer(ip) :: l
        integer(ip) :: lat
        integer(ip) :: late
        integer(ip) :: lm1
        integer(ip) :: lp1
        integer(ip) :: m
        integer(ip) :: mdab
        integer(ip) :: meo
        integer(ip) :: mode
        integer(ip) :: mp1
        integer(ip) :: mp2
        integer(ip) :: ms
        integer(ip) :: ndab
        integer(ip) :: nl2
        integer(ip) :: nlat
        integer(ip) :: nlon
        integer(ip) :: np1
        integer(ip) :: ns
        integer(ip) :: nt
        real(wp) :: pmn
        real(wp) :: t1
        real(wp) :: t2
        real(wp) :: t3
        real(wp) :: t4
        real(wp) :: w
        real(wp) :: wfft
        dimension gs(idg, jdg, nt), a(mdab, ndab, nt), b(mdab, ndab, nt)
        dimension w(*), pmn(nlat, late, 3), g(lat, nlon, nt), wfft(*)

        type(SpherepackUtility) :: util

        !     reconstruct fourier coefficients in g on gaussian grid
        !     using coefficients in a, b
        !     set m+1 limit for b coefficient calculation
        lm1 = l
        if (nlon == 2*l-2) lm1 = l-1

        !     initialize to zero
        g = ZERO

        if (mode == 0) then
            !     set first column in g
            m = 0
            !     compute pmn for all i and n=m, ..., l-1
            call util%compute_legendre_polys_for_gaussian_grids(mode, l, nlat, m, w, pmn, km)
            do k=1, nt
                !     n even
                do np1=1, nlat, 2
                    do i=1, late
                        g(i, 1, k) = g(i, 1, k)+a(1, np1, k)*pmn(np1, i, km)
                    end do
                end do
                !     n odd
                nl2 = nlat/2
                do np1=2, nlat, 2
                    do i=1, nl2
                        is = nlat-i+1
                        g(is, 1, k) = g(is, 1, k)+a(1, np1, k)*pmn(np1, i, km)
                    end do
                end do
                !     restore m=0 coefficents (reverse implicit even/odd reduction)
                do i=1, nl2
                    is = nlat-i+1
                    t1 = g(i, 1, k)
                    t3 = g(is, 1, k)
                    g(i, 1, k) = t1+t3
                    g(is, 1, k) = t1-t3
                end do
            end do
            !     sweep  columns of g for which b is available
            do mp1=2, lm1
                m = mp1-1
                mp2 = m+2
                !     compute pmn for all i and n=m, ..., l-1
                call util%compute_legendre_polys_for_gaussian_grids(mode, l, nlat, m, w, pmn, km)
                do k=1, nt
                    !     for n-m even store (g(i, p, k)+g(nlat-i+1, p, k))/2 in g(i, p, k) p=2*m, 
                    !     for i=1, ..., late
                    do np1=mp1, nlat, 2
                        do i=1, late
                            g(i, 2*m, k) = g(i, 2*m, k)+a(mp1, np1, k)*pmn(np1, i, km)
                            g(i, 2*m+1, k) = g(i, 2*m+1, k)+b(mp1, np1, k)*pmn(np1, i, km)
                        end do
                    end do
                    !     for n-m odd store g(i, p, k)-g(nlat-i+1, p, k) in g(nlat-i+1, p, k)
                    !     for i=1, ..., nlat/2 (p=2*m, p=2*m+1)
                    do np1=mp2, nlat, 2
                        do i=1, nl2
                            is = nlat-i+1
                            g(is, 2*m, k) = g(is, 2*m, k)+a(mp1, np1, k)*pmn(np1, i, km)
                            g(is, 2*m+1, k) = g(is, 2*m+1, k)+b(mp1, np1, k)*pmn(np1, i, km)
                        end do
                    end do
                    !     now set fourier coefficients using even-odd reduction above
                    do i=1, nl2
                        is = nlat-i+1
                        t1 = g(i, 2*m, k)
                        t2 = g(i, 2*m+1, k)
                        t3 = g(is, 2*m, k)
                        t4 = g(is, 2*m+1, k)
                        g(i, 2*m, k) = t1+t3
                        g(i, 2*m+1, k) = t2+t4
                        g(is, 2*m, k) = t1-t3
                        g(is, 2*m+1, k) = t2-t4
                    end do
                end do
            end do
            !     set last column (using a only)
            if (nlon== l+l-2) then
                m = l-1
                call util%compute_legendre_polys_for_gaussian_grids(mode, l, nlat, m, w, pmn, km)
                do k=1, nt
                    !     n-m even
                    do np1=l, nlat, 2
                        do i=1, late
                            g(i, nlon, k) = g(i, nlon, k)+TWO*a(l, np1, k)*pmn(np1, i, km)
                        end do
                    end do
                    lp1 = l+1
                    !     n-m odd
                    do np1=lp1, nlat, 2
                        do i=1, nl2
                            is = nlat-i+1
                            g(is, nlon, k) = g(is, nlon, k)+TWO*a(l, np1, k)*pmn(np1, i, km)
                        end do
                    end do
                    do i=1, nl2
                        is = nlat-i+1
                        t1 = g(i, nlon, k)
                        t3 = g(is, nlon, k)
                        g(i, nlon, k)= t1+t3
                        g(is, nlon, k)= t1-t3
                    end do
                end do
            end if
        else
            !     half sphere (mode.ne.0)
            !     set first column in g
            m = 0
            meo = 1
            if (mode == 1) meo = 2
            ms = m+meo
            !     compute pmn for all i and n=m, ..., l-1
            call util%compute_legendre_polys_for_gaussian_grids(mode, l, nlat, m, w, pmn, km)
            do k=1, nt
                do np1=ms, nlat, 2
                    do i=1, late
                        g(i, 1, k) = g(i, 1, k)+a(1, np1, k)*pmn(np1, i, km)
                    end do
                end do
            end do
            !     sweep interior columns of g
            do mp1=2, lm1
                m = mp1-1
                ms = m+meo
                !     compute pmn for all i and n=m, ..., l-1
                call util%compute_legendre_polys_for_gaussian_grids(mode, l, nlat, m, w, pmn, km)
                do k=1, nt
                    do np1=ms, nlat, 2
                        do i=1, late
                            g(i, 2*m, k) = g(i, 2*m, k)+a(mp1, np1, k)*pmn(np1, i, km)
                            g(i, 2*m+1, k) = g(i, 2*m+1, k)+b(mp1, np1, k)*pmn(np1, i, km)
                        end do
                    end do
                end do
            end do
            if (nlon==l+l-2) then
                !     set last column
                m = l-1
                call util%compute_legendre_polys_for_gaussian_grids(mode, l, nlat, m, w, pmn, km)
                ns = l
                if (mode == 1) ns = l+1
                do k=1, nt
                    do i=1, late
                        do np1=ns, nlat, 2
                            g(i, nlon, k) = g(i, nlon, k)+TWO*a(l, np1, k)*pmn(np1, i, km)
                        end do
                    end do
                end do
            end if
        end if
        !     do inverse fourier transform
        do k=1, nt
            call util%hfft%backward(lat, nlon, g(:, :, k), lat, wfft)
        end do
        !     scale output in gs
        do k=1, nt
            do j=1, nlon
                do i=1, lat
                    gs(i, j, k) = HALF * g(i, j, k)
                end do
            end do
        end do

    end subroutine shsgc_lower_utility_routine

    subroutine shsgci_lower_utility_routine(nlat, nlon, l, late, wts, p0n, p1n, abel, bbel, cbel, &
        wfft, dtheta, dwts, work, ier)

        real(wp) :: abel
        real(wp) :: bbel
        real(wp) :: cbel
        integer(ip) :: i
        integer(ip) :: ier
        integer(ip) :: imn
        
        
        integer(ip) :: l
        integer(ip) :: late
        integer(ip) :: lw
        integer(ip) :: m
        integer(ip) :: mlim
        integer(ip) :: n
        integer(ip) :: nlat
        integer(ip) :: nlon
        integer(ip) :: np1
        real(wp) :: p0n
        real(wp) :: p1n
        real(wp) :: wfft
        real(wp) :: wts
        dimension wts(nlat), p0n(nlat, late), p1n(nlat, late), abel(*), bbel(*), &
            cbel(*), wfft(*)
        real(wp) :: pb, dtheta(nlat), dwts(nlat), work(*)
        type(SpherepackUtility) :: util

        !     compute the nlat  gaussian points and weights, the
        !     m=0, 1 legendre polys for gaussian points and all n, 
        !     and the legendre recursion coefficients
        !     define index function used in storing
        !     arrays for recursion coefficients (functions of (m, n))
        !     the index function indx(m, n) is defined so that
        !     the pairs (m, n) map to [1, 2, ..., indx(l-1, l-1)] with no
        !     "holes" as m varies from 2 to n and n varies from 2 to l-1.
        !     (m=0, 1 are set from p0n, p1n for all n)
        !     define for 2<=n<=l-1
        !indx(m, n) = (n-1)*(n-2)/2+m-1
        !     define index function for l<=n<=nlat
        !imndx(m, n) = l*(l-1)/2+(n-l-1)*(l-1)+m-1
        !     preset quantites for fourier transform
        call util%hfft%initialize(nlon, wfft)
        !     compute real gaussian points and weights
        !     lw = 4*nlat*(nlat+1)+2
        lw = nlat*(nlat+2)
        call compute_gaussian_latitudes_and_weights(nlat, dtheta, dwts, ier)
        if (ier/=0) return
        !     store gaussian weights single precision to save computation
        !     in inner loops in analysis
        wts = dwts
        !     initialize p0n, p1n using real dnlfk, dnlft
        p0n = ZERO
        p1n = ZERO

        !     compute m=n=0 legendre polynomials for all theta(i)
        np1 = 1
        n = 0
        m = 0
        call util%compute_fourier_coefficients(m, n, work)
        do i=1, late
            call util%compute_legendre_polys_from_fourier_coeff(m, n, dtheta(i), work, pb)
            p0n(1, i) = pb
        end do
        !     compute p0n, p1n for all theta(i) when n>0
        do np1=2, nlat
            n = np1-1
            m = 0
            call util%compute_fourier_coefficients(m, n, work)
            do i=1, late
                call util%compute_legendre_polys_from_fourier_coeff(m, n, dtheta(i), work, pb)
                p0n(np1, i) = pb
            end do
            !     compute m=1 legendre polynomials for all n and theta(i)
            m = 1
            call util%compute_fourier_coefficients(m, n, work)
            do i=1, late
                call util%compute_legendre_polys_from_fourier_coeff(m, n, dtheta(i), work, pb)
                p1n(np1, i) = pb
            end do
        end do
        !     compute and store swarztrauber recursion coefficients
        !     for 2<=m<=n and 2<=n<=nlat in abel, bbel, cbel
        do n=2, nlat
            mlim = min(n, l)
            do m=2, mlim

                if (n >= l) then
                    imn = l*(l-1)/2+(n-l-1)*(l-1)+m-1
                else
                    imn = (n-1)*(n-2)/2+m-1
                end if

                abel(imn)=sqrt(real((2*n+1)*(m+n-2)*(m+n-3))/ &
                    real(((2*n-3)*(m+n-1)*(m+n))))
                bbel(imn)=sqrt(real((2*n+1)*(n-m-1)*(n-m))/ &
                    real(((2*n-3)*(m+n-1)*(m+n))))
                cbel(imn)=sqrt(real((n-m+1)*(n-m+2))/ &
                    real(((n+m-1)*(n+m))))
            end do
        end do

    end subroutine shsgci_lower_utility_routine

end submodule scalar_synthesis_gaussian_grid
