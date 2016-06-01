!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 1998 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                      SPHEREPACK version 3.2                   *
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
!
!
! ... file dives.f
!
!     this file includes documentation and code for
!     subroutine dives          i
!
! ... files which must be loaded with dives.f
!
!     sphcom.f, hrfft.f, vhaes.f, shses.f
!
!
!     subroutine dives(nlat, nlon, isym, nt, dv, idv, jdv, br, bi, mdb, ndb, 
!    +                 wshses, lshses, work, lwork, ierror)
!
!     given the vector spherical harmonic coefficients br and bi, precomputed
!     by subroutine vhaes for a vector field (v, w), subroutine dives
!     computes the divergence of the vector field in the scalar array dv.
!     dv(i, j) is the divergence at the colatitude
!
!            theta(i) = (i-1)*pi/(nlat-1)
!
!     and east longitude
!
!            lambda(j) = (j-1)*2*pi/nlon
!
!     on the sphere.  i.e.
!
!            dv(i, j) = 1/sint*[ d(sint*v(i, j))/dtheta + d(w(i, j))/dlambda ]
!
!     where sint = sin(theta(i)).  w is the east longitudinal and v
!     is the colatitudinal component of the vector field from which
!     br, bi were precomputed.  required associated legendre polynomials
!     are stored rather than recomputed as they are in subroutine divec.
!
!
!     input parameters
!
!     nlat   the number of colatitudes on the full sphere including the
!            poles. for example, nlat = 37 for a five degree grid.
!            nlat determines the grid increment in colatitude as
!            pi/(nlat-1).  if nlat is odd the equator is located at
!            grid point i=(nlat+1)/2. if nlat is even the equator is
!            located half way between points i=nlat/2 and i=nlat/2+1.
!            nlat must be at least 3. note: on the half sphere, the
!            number of grid points in the colatitudinal direction is
!            nlat/2 if nlat is even or (nlat+1)/2 if nlat is odd.
!
!     nlon   the number of distinct londitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater than
!            3.  the efficiency of the computation is improved when nlon
!            is a product of small prime numbers.
!
!
!     isym   a parameter which determines whether the divergence is
!            computed on the full or half sphere as follows:
!
!      = 0
!
!            the symmetries/antsymmetries described in isym=1, 2 below
!            do not exist in (v, w) about the equator.  in this case the
!            divergence is neither symmetric nor antisymmetric about
!            the equator.  the divergence is computed on the entire
!            sphere.  i.e., in the array dv(i, j) for i=1, ..., nlat and
!            j=1, ..., nlon.
!
!      = 1
!
!            w is antisymmetric and v is symmetric about the equator.
!            in this case the divergence is antisymmetyric about
!            the equator and is computed for the northern hemisphere
!            only.  i.e., if nlat is odd the divergence is computed
!            in the array dv(i, j) for i=1, ..., (nlat+1)/2 and for
!            j=1, ..., nlon.  if nlat is even the divergence is computed
!            in the array dv(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
!
!      = 2
!            w is symmetric and v is antisymmetric about the equator
!            in this case the divergence is symmetyric about the
!            equator and is computed for the northern hemisphere
!            only.  i.e., if nlat is odd the divergence is computed
!            in the array dv(i, j) for i=1, ..., (nlat+1)/2 and for
!            j=1, ..., nlon.  if nlat is even the divergence is computed
!            in the array dv(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
!
!
!     nt     nt is the number of scalar and vector fields.  some
!            computational efficiency is obtained for multiple fields.
!            can be three dimensional corresponding to an indexed multiple
!            vector field.  in this case multiple scalar synthesis will
!            be performed to compute the divergence for each field.  the
!            third index is the synthesis index which assumes the values
!            k=1, ..., nt.  for a single synthesis set nt = 1.  the
!            description of the remaining parameters is simplified by
!            assuming that nt=1 or that all the arrays are two dimensional.
!
!     idv    the first dimension of the array dv as it appears in
!            the program that calls dives. if isym = 0 then idv
!            must be at least nlat.  if isym = 1 or 2 and nlat is
!            even then idv must be at least nlat/2. if isym = 1 or 2
!            and nlat is odd then idv must be at least (nlat+1)/2.
!
!     jdv    the second dimension of the array dv as it appears in
!            the program that calls dives. jdv must be at least nlon.
!
!     br, bi  two or three dimensional arrays (see input parameter nt)
!            that contain vector spherical harmonic coefficients
!            of the vector field (v, w) as computed by subroutine vhaes.
!     ***    br and bi must be computed by vhaes prior to calling
!            dives.
!
!     mdb    the first dimension of the arrays br and bi as it
!            appears in the program that calls dives. mdb must be at
!            least min(nlat, nlon/2) if nlon is even or at least
!            min(nlat, (nlon+1)/2) if nlon is odd.
!
!     ndb    the second dimension of the arrays br and bi as it
!            appears in the program that calls dives. ndb must be at
!            least nlat.
!
!
!     wshses an array which must be initialized by subroutine shsesi
!            once initialized, 
!            wshses can be used repeatedly by dives as long as nlon
!            and nlat remain unchanged.  wshses must not be altered
!            between calls of dives.  wdives is identical to the saved
!            work space initialized by subroutine shsesi and can be
!            set by calling that subroutine instead of divesi.
!
!
!     lshses the dimension of the array wshses as it appears in the
!            program that calls dives. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshses must be at least
!
!              (l1*l2*(nlat+nlat-l1+1))/2+nlon+15
!
!
!     work   a work array that does not have to be saved.
!
!     lwork  the dimension of the array work as it appears in the
!            program that calls dives. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2                    if nlat is even or
!               l2 = (nlat+1)/2                if nlat is odd
!
!            if isym = 0 then lwork must be at least
!
!               nlat*((nt+1)*nlon+2*nt*l1+1)
!
!            if isym > 0 then lwork must be at least
!
!               (nt+1)*l2*nlon+nlat*(2*nt*l1+1)
!
!     **************************************************************
!
!     output parameters
!
!
!    dv     a two or three dimensional array (see input parameter nt)
!           that contains the divergence of the vector field (v, w)
!           whose coefficients br, bi where computed by subroutine
!           vhaes.  dv(i, j) is the divergence at the colatitude point
!           theta(i) = (i-1)*pi/(nlat-1) and longitude point
!           lambda(j) = (j-1)*2*pi/nlon. the index ranges are defined
!           above at the input parameter isym.
!
!
!    ierror = 0  no errors
!           = 1  error in the specification of nlat
!           = 2  error in the specification of nlon
!           = 3  error in the specification of isym
!           = 4  error in the specification of nt
!           = 5  error in the specification of idv
!           = 6  error in the specification of jdv
!           = 7  error in the specification of mdb
!           = 8  error in the specification of ndb
!           = 9  error in the specification of lshses
!           = 10 error in the specification of lwork
! **********************************************************************
!                                                                              
!   
subroutine dives(nlat, nlon, isym, nt, dv, idv, jdv, br, bi, mdb, ndb, &
    wshses, lshses, work, lwork, ierror)
    implicit none
    real :: bi
    real :: br
    real :: dv
    integer :: ia
    integer :: ib
    integer :: idv
    integer :: ierror
    integer :: imid
    integer :: is
    integer :: isym
    integer :: iwk
    integer :: jdv
    integer :: lpimn
    integer :: ls
    integer :: lshses
    integer :: lwk
    integer :: lwork
    integer :: mab
    integer :: mdb
    integer :: mmax
    integer :: mn
    integer :: ndb
    integer :: nlat
    integer :: nln
    integer :: nlon
    integer :: nt
    real :: work
    real :: wshses

    dimension dv(idv, jdv, nt), br(mdb, ndb, nt), bi(mdb, ndb, nt)
    dimension wshses(lshses), work(lwork)
    !
    !     check input parameters
    !
    ierror = 1
    if (nlat < 3) return
    ierror = 2
    if (nlon < 4) return
    ierror = 3
    if (isym < 0 .or. isym > 2) return
    ierror = 4
    if (nt < 0) return
    ierror = 5
    imid = (nlat+1)/2
    if ((isym == 0 .and. idv<nlat) .or. &
        (isym>0 .and. idv<imid)) return
    ierror = 6
    if (jdv < nlon) return
    ierror = 7
    if (mdb < min(nlat, (nlon+1)/2)) return
    mmax = min(nlat, (nlon+2)/2)
    ierror = 8
    if (ndb < nlat) return
    ierror = 9
    !
    !     verify save work space (same as shes, file f3)
    !
    imid = (nlat+1)/2
    lpimn = (imid*mmax*(nlat+nlat-mmax+1))/2
    if (lshses < lpimn+nlon+15) return
    ierror = 10
    !
    !     verify unsaved work space (add to what shses requires, file f3)
    !
    ls = nlat
    if (isym > 0) ls = imid
    nln = nt*ls*nlon
    !
    !     set first dimension for a, b (as requried by shses)
    !
    mab = min(nlat, nlon/2+1)
    mn = mab*nlat*nt
    if (lwork < nln+ls*nlon+2*mn+nlat) return
    ierror = 0
    !
    !     set work space pointers
    !
    ia = 1
    ib = ia+mn
    is = ib+mn
    iwk = is+nlat
    lwk = lwork-2*mn-nlat

    call dives1(nlat, nlon, isym, nt, dv, idv, jdv, br, bi, mdb, ndb, &
        work(ia), work(ib), mab, work(is), wshses, lshses, work(iwk), lwk, &
        ierror)

end subroutine dives



subroutine dives1(nlat, nlon, isym, nt, dv, idv, jdv, br, bi, mdb, ndb, &
    a, b, mab, sqnn, wshses, lshses, wk, lwk, ierror)
    implicit none
    real :: a
    real :: b
    real :: bi
    real :: br
    real :: dv
    real :: fn
    integer :: idv
    integer :: ierror
    integer :: isym
    integer :: jdv
    integer :: k
    integer :: lshses
    integer :: lwk
    integer :: m
    integer :: mab
    integer :: mdb
    integer :: mmax
    integer :: n
    integer :: ndb
    integer :: nlat
    integer :: nlon
    integer :: nt
    real :: sqnn
    real :: wk
    real :: wshses
    dimension dv(idv, jdv, nt), br(mdb, ndb, nt), bi(mdb, ndb, nt)
    dimension a(mab, nlat, nt), b(mab, nlat, nt), sqnn(nlat)
    dimension wshses(lshses), wk(lwk)
    !
    !     set coefficient multiplyers
    !
    do n=2, nlat
        fn = real(n - 1)
        sqnn(n) = sqrt(fn * (fn + 1.0))
    end do
    !
    !     compute divergence scalar coefficients for each vector field
    !
    do  k=1, nt
        do  n=1, nlat
            do  m=1, mab
                a(m, n, k) = 0.0
                b(m, n, k) = 0.0
            end do
        end do
        !
        !     compute m=0 coefficients
        !
        do  n=2, nlat
            a(1, n, k) = -sqnn(n)*br(1, n, k)
            b(1, n, k) = -sqnn(n)*bi(1, n, k)
        end do
        !
        !     compute m>0 coefficients using vector spherepack value for mmax
        !
        mmax = min(nlat, (nlon+1)/2)
        do  m=2, mmax
            do  n=m, nlat
                a(m, n, k) = -sqnn(n)*br(m, n, k)
                b(m, n, k) = -sqnn(n)*bi(m, n, k)
            end do
        end do
    end do
    !
    !     synthesize a, b into dv
    !
    call shses(nlat, nlon, isym, nt, dv, idv, jdv, a, b, &
        mab, nlat, wshses, lshses, wk, lwk, ierror)

end subroutine dives1
