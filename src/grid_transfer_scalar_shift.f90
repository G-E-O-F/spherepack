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
!
! ... file sshifte.f contains code and documentation for subroutine sshifte
!     and its' initialization subroutine sshifti
!
! ... required spherepack files 
!
!     type_RealPeriodicFastFourierTransform.f
!
!     subroutine sshifte(ioff, nlon, nlat, goff, greg, wsav, lsav, work, lwork, ier)
!
! *** purpose
!
!     subroutine sshifte does a highly accurate 1/2 grid increment shift
!     in both longitude and latitude of equally spaced data on the sphere.
!     data is transferred between the nlon by nlat "offset grid" in goff
!     (which excludes poles) and the nlon by nlat+1 "regular grid" in greg
!     (which includes poles).  the transfer can go from goff to greg or from
!     greg to goff (see ioff).  the grids which underly goff and greg are
!     described below.  the north and south poles are at latitude HALF*pi and
!     -HALF*pi radians respectively.
!
! *** grid descriptions
!
!     let dlon = (pi+pi)/nlon and dlat = pi/nlat be the uniform grid
!     increments in longitude and latitude
!
!     offset grid
!
!     the "1/2 increment offset" grid (long(j), lat(i)) on which goff(j, i)
!     is given (ioff=0) or generated (ioff=1) is
!
!          long(j) =HALF*dlon + (j-1)*dlon  (j=1, ..., nlon)
!
!     and
!
!          lat(i) = -HALF*pi + HALF*dlat + (i-1)*dlat (i=1, ..., nlat)
!
!     the data in goff is "shifted" one half a grid increment in longitude
!     and latitude and excludes the poles.  each goff(j, 1) is given at
!     latitude -HALF*pi+HALF*dlat and goff(j, nlat) is given at HALF*pi-HALF*dlat
!     (1/2 a grid increment away from the poles).  each goff(1, i), goff(nlon, i)
!     is given at longitude HALF*dlon and 2.*pi-HALF*dlon.
!
!     regular grid
!
!     let dlat, dlon be as above.  then the nlon by nlat+1 grid on which
!     greg(j, i) is generated (ioff=0) or given (ioff=1) is given by
!
!          lone(j) = (j-1)*dlon (j=1, ..., nlon)
!
!      and
!
!          late(i) = -HALF*pi + (i-1)*dlat (i=1, ..., nlat+1)
!
!     values in greg include the poles and start at zero degrees longitude.
!
! *** remark
!
!     subroutine sshifte can be used in conjunction with subroutine trssph
!     when transferring data from an equally spaced "1/2 increment offset"
!     grid to a gaussian or equally spaced grid (which includes poles) of
!     any resolution.  this problem (personal communication with dennis
!     shea) is encountered in geophysical modeling and data analysis.
!
! *** method
!
!     fast fourier transform software from spherepack2 and trigonometric
!     identities are used to accurately "shift" periodic vectors half a
!     grid increment in latitude and longitude.  latitudinal shifts are
!     accomplished by setting periodic 2*nlat vectors over the pole for each
!     longitude.  when nlon is odd, this requires an additional longitude
!     shift.  longitudinal shifts are then executed for each shifted latitude.
!     when necessary (ioff=0) poles are obtained by averaging the nlon
!     shifted polar values.
!
! *** required spherepack files
!
!     type_RealPeriodicFastFourierTransform.f
!
! *** argument description
!
! ... ioff
!
!     ioff = 0 if values on the offset grid in goff are given and values
!              on the regular grid in greg are to be generated.
!
!     ioff = 1 if values on the regular grid in greg are given and values
!              on the offset grid in goff are to be generated.
!
! ... nlon
!
!     the number of longitude points on both the "offset" and "regular"
!     uniform grid in longitude (see "grid description" above).  nlon
!     is also the first dimension of array goff and greg.  nlon determines
!     the grid increment in longitude as dlon = 2.*pi/nlon.  for example, 
!     nlon = 144 for a 2.5 degree grid.  nlon can be even or odd and must
!     be greater than or equal to 4.  the efficiency of the computation
!     is improved when nlon is a product of small primes.
!
! ... nlat
!
!     the number of latitude points on the "offset" uniform grid.  nlat+1
!     is the number of latitude points on the "regular" uniform grid (see
!     "grid description" above).  nlat is the second dimension of array goff.
!     nlat+1 must be the second dimension of the array greg in the program
!     calling sshifte.  nlat determines the grid in latitude as pi/nlat.
!     for example, nlat = 36 for a five degree grid.  nlat must be at least 3.
!
! ... goff
!
!     a nlon by nlat array that contains data on the offset grid
!     described above.  goff is a given input argument if ioff=0.
!     goff is a generated output argument if ioff=1.
!
! ... greg
!
!     a nlon by nlat+1 array that contains data on the regular grid
!     described above.  greg is a given input argument if ioff=1.
!     greg is a generated output argument if ioff=0.
!
! ... wsav
!
!     a real saved work space array that must be initialized by calling
!     subroutine sshifti(ioff, nlon, nlat, wsav, ier) before calling sshifte.
!     wsav can then be used repeatedly by sshifte as long as ioff, nlon, 
!     and nlat do not change.  this bypasses redundant computations and
!     saves time.  undetectable errors will result if sshifte is called
!     without initializing wsav whenever ioff, nlon, or nlat change.
!
! ... lsav
!
!     the length of the saved work space wsav in the routine calling sshifte
!     and sshifti.  lsave must be greater than or equal to 2*(2*nlat+nlon+16).
!
! ... work
!
!     a real unsaved work space
!
! ... lwork
!
!     the length of the unsaved work space in the routine calling sshifte
!     lwork must be greater than or equal to 2*nlon*(nlat+1) if nlon is even.
!     lwork must be greater than or equal to nlon*(5*nlat+1) if nlon is odd.
!
! ... ier
!
!     indicates errors in input parameters
!
!     = 0 if no errors are detected
!
!     = 1 if ioff is not equal to 0 or 1
!
!     = 1 if nlon < 4
!
!     = 2 if nlat < 3
!
!     = 3 if lsave < 2*(nlon+2*nlat+16)
!
!     = 4 if lwork < 2*nlon*(nlat+1) for nlon even or
!            lwork < nlon*(5*nlat+1) for nlon odd
!
! *** end of sshifte documentation
!
!     subroutine sshifti(ioff, nlon, nlat, lsav, wsav, ier)
!
!     subroutine sshifti initializes the saved work space wsav
!     for ioff and nlon and nlat (see documentation for sshifte).
!     sshifti must be called before sshifte whenever ioff or nlon
!     or nlat change.
!
! ... ier
!
!     = 0 if no errors with input arguments
!
!     = 1 if ioff is not 0 or 1
!
!     = 2 if nlon < 4
!
!     = 3 if nlat < 3
!
!     = 4 if lsav < 2*(2*nlat+nlon+16)
!
! *** end of sshifti documentation
!
module module_sshifte

    use spherepack_precision, only: &
        wp, & ! working precision
        ip, & ! integer precision
        PI

    use type_RealPeriodicFastFourierTransform, only: &
        RealPeriodicFastFourierTransform

    ! Explicit typing only
    implicit none

    ! Everything is private unless stated otherwise
    public :: sshifte
    public :: sshifti

    ! Parameters confined to the module
    real(wp), parameter :: ZERO = 0.0_wp
    real(wp), parameter :: HALF = 0.5_wp

contains

    subroutine sshifte(ioff, nlon, nlat, goff, greg, wsav, lsav, &
        wrk, lwrk, ier)

        integer(ip) :: ioff, nlon, nlat, n2, nr, nlat2, nlatp1, lsav, lwrk, i1, i2, ier
        real(wp) :: goff(nlon, nlat), greg(nlon, *), wsav(lsav), wrk(lwrk)
        !
        ! Check calling arguments
        !
        ier = 1
        if (ioff*(ioff-1)/=0) return
        ier = 2
        if (nlon < 4) return
        ier = 3
        if (nlat < 3) return
        ier = 4
        if (lsav < 2*(2*nlat+nlon+16)) return
        ier = 5
        n2 = (nlon+1)/2
        if (2*n2 == nlon) then
            if ( lwrk < 2*nlon*(nlat+1)) return
            i1 = 1
            nr = n2
        else
            if ( lwrk < nlon*(5*nlat+1)) return
            i1 = 1+2*nlat*nlon
            nr = nlon
        end if
        ier = 0
        nlat2 = nlat+nlat
        i2 = i1 + (nlat+1)*nlon
        if (ioff==0) then
            call shftoff(nlon, nlat, goff, greg, wsav, nr, nlat2, &
                wrk, wrk(i1), wrk(i2))
        else
            nlatp1 = nlat+1
            call shftreg(nlon, nlat, goff, greg, wsav, nr, nlat2, nlatp1, &
                wrk, wrk(i1), wrk(i2))
        end if

    end subroutine sshifte


    subroutine shftoff(nlon, nlat, goff, greg, wsav, nr, nlat2, &
        rlat, rlon, wrk)
        !
        !     shift offset grid to regular grid, i.e., 
        !     goff is given, greg is to be generated
        !

        integer(ip) :: nlon, nlat, nlat2, n2, nr, j, i, js, isav
        real(wp) :: goff(nlon, nlat), greg(nlon, nlat+1)
        real(wp) :: rlat(nr, nlat2), rlon(nlat, nlon)
        real(wp) :: wsav(*), wrk(*)
        real(wp) :: gnorth, gsouth
        isav = 4*nlat+17
        n2 = (nlon+1)/2
        !
        !     execute full circle latitude shifts for nlon odd or even
        !
        if (2*n2 > nlon) then
            !
            !     odd number of longitudes
            !
            do i=1, nlat
                do j=1, nlon
                    rlon(i, j) = goff(j, i)
                end do
            end do
            !
            !       half shift in longitude
            !
            call shifth(nlat, nlon, rlon, wsav(isav), wrk)
                !
                !       set full 2*nlat circles in rlat using shifted values in rlon
                !
            do j=1, n2-1
                js = j+n2
                do i=1, nlat
                    rlat(j, i)      = goff(j, i)
                    rlat(j, nlat+i) = rlon(nlat+1-i, js)
                end do
            end do
            do j=n2, nlon
                js = j-n2+1
                do i=1, nlat
                    rlat(j, i)      = goff(j, i)
                    rlat(j, nlat+i) = rlon(nlat+1-i, js)
                end do
            end do
            !
            !       shift the nlon rlat vectors one half latitude grid
            !
            call shifth(nlon, nlat2, rlat, wsav, wrk)
                !
                !       set nonpole values in greg and average for poles
                !
            gnorth = ZERO
            gsouth = ZERO
            do j=1, nlon
                gnorth = gnorth + rlat(j, 1)
                gsouth = gsouth + rlat(j, nlat+1)
                do i=2, nlat
                    greg(j, i) =  rlat(j, i)
                end do
            end do
            gnorth = gnorth/nlon
            gsouth = gsouth/nlon

        else
                !
                !     even number of longitudes (no initial longitude shift necessary)
                !     set full 2*nlat circles (over poles) for each longitude pair (j, js)
                !
            do j=1, n2
                js = n2+j
                do i=1, nlat
                    rlat(j, i)      = goff(j, i)
                    rlat(j, nlat+i) = goff(js, nlat+1-i)
                end do
            end do
            !
            !       shift the n2=(nlon+1)/2 rlat vectors one half latitude grid
            !
            call shifth(n2, nlat2, rlat, wsav, wrk)
            !
            !       set nonpole values in greg and average poles
            !
            gnorth = ZERO
            gsouth = ZERO
            do j=1, n2
                js = n2+j
                gnorth = gnorth + rlat(j, 1)
                gsouth = gsouth + rlat(j, nlat+1)
                do i=2, nlat
                    greg(j, i) =  rlat(j, i)
                    greg(js, i) = rlat(j, nlat2-i+2)
                end do
            end do
            gnorth = gnorth/n2
            gsouth = gsouth/n2
        end if

        !
        !     set poles
        !
        do j=1, nlon
            greg(j, 1)      = gnorth
            greg(j, nlat+1) = gsouth
        end do
        !
        !     execute full circle longitude shift
        !
        do j=1, nlon
            do i=1, nlat
                rlon(i, j) = greg(j, i)
            end do
        end do

        call shifth(nlat, nlon, rlon, wsav(isav), wrk)

        do j=1, nlon
            do i=2, nlat
                greg(j, i) = rlon(i, j)
            end do
        end do

    end subroutine shftoff

    subroutine shftreg(nlon, nlat, goff, greg, wsav, nr, nlat2, nlatp1, &
        rlat, rlon, wrk)
        !
        !     shift regular grid to offset grid, i.e., 
        !     greg is given, goff is to be generated
        !

        integer(ip) :: nlon, nlat, nlat2, nlatp1, n2, nr, j, i, js, isav
        real(wp) :: goff(nlon, nlat), greg(nlon, nlatp1)
        real(wp) :: rlat(nr, nlat2), rlon(nlatp1, nlon)
        real(wp) :: wsav(*), wrk(*)
        isav = 4*nlat+17
        n2 = (nlon+1)/2
        !
        !     execute full circle latitude shifts for nlon odd or even
        !
        if (2*n2 > nlon) then
                !
                !     odd number of longitudes
                !
            do i=1, nlat+1
                do j=1, nlon
                    rlon(i, j) = greg(j, i)
                end do
            end do
            !
            !       half shift in longitude in rlon
            !
            call shifth(nlat+1, nlon, rlon, wsav(isav), wrk)
                !
                !       set full 2*nlat circles in rlat using shifted values in rlon
                !
            do j=1, n2
                js = j+n2-1
                rlat(j, 1) = greg(j, 1)
                do i=2, nlat
                    rlat(j, i) = greg(j, i)
                    rlat(j, nlat+i) = rlon(nlat+2-i, js)
                end do
                rlat(j, nlat+1) = greg(j, nlat+1)
            end do
            do j=n2+1, nlon
                js = j-n2
                rlat(j, 1) = greg(j, 1)
                do i=2, nlat
                    rlat(j, i) = greg(j, i)
                    rlat(j, nlat+i) = rlon(nlat+2-i, js)
                end do
                rlat(j, nlat+1) = greg(j, nlat+1)
            end do
            !
            !       shift the nlon rlat vectors one halflatitude grid
            !
            call shifth(nlon, nlat2, rlat, wsav, wrk)
                !
                !       set values in goff
                !
            do j=1, nlon
                do i=1, nlat
                    goff(j, i) =  rlat(j, i)
                end do
            end do

        else
            !
            !     even number of longitudes (no initial longitude shift necessary)
            !     set full 2*nlat circles (over poles) for each longitude pair (j, js)
            !
            do j=1, n2
                js = n2+j
                rlat(j, 1) = greg(j, 1)
                do i=2, nlat
                    rlat(j, i) = greg(j, i)
                    rlat(j, nlat+i) = greg(js, nlat+2-i)
                end do
                rlat(j, nlat+1) = greg(j, nlat+1)
            end do
            !
            !       shift the n2=(nlon+1)/2 rlat vectors one half latitude grid
            !
            call shifth(n2, nlat2, rlat, wsav, wrk)
            !
            !       set values in goff
            !
            do j=1, n2
                js = n2+j
                do i=1, nlat
                    goff(j, i) =  rlat(j, i)
                    goff(js, i) = rlat(j, nlat2+1-i)
                end do
            end do
        end if

        !
        !     execute full circle longitude shift for all latitude circles
        !
        do j=1, nlon
            do i=1, nlat
                rlon(i, j) = goff(j, i)
            end do
        end do

        call shifth(nlat+1, nlon, rlon, wsav(isav), wrk)

        do j=1, nlon
            do i=1, nlat
                goff(j, i) = rlon(i, j)
            end do
        end do

    end subroutine shftreg



    subroutine sshifti(ioff, nlon, nlat, lsav, wsav, ier)

        integer(ip) :: lsav
        integer(ip) :: ioff, nlat, nlon, nlat2, isav, ier
        real(wp) :: wsav(lsav)
        real(wp) :: dlat, dlon, dp
        ier = 1
        if (ioff*(ioff-1)/=0) return
        ier = 2
        if (nlon < 4) return
        ier = 3
        if (nlat < 3) return
        ier = 4
        if (lsav < 2*(2*nlat+nlon+16)) return
        ier = 0
        !
        !     set lat, long increments
        !
        dlat = pi/nlat
        dlon = (pi+pi)/nlon
        !
        !     initialize wsav for left or right latitude shifts
        !
        if (ioff==0) then
            dp = -HALF*dlat
        else
            dp = HALF*dlat
        end if
        nlat2 = nlat+nlat
        call shifthi(nlat2, dp, wsav)
        !
        !     initialize wsav for left or right longitude shifts
        !
        if (ioff==0) then
            dp = -HALF*dlon
        else
            dp = HALF*dlon
        end if
        isav = 4*nlat + 17
        call shifthi(nlon, dp, wsav(isav))

    end subroutine sshifti

    subroutine shifth(m, n, r, wsav, work)

        type(RealPeriodicFastFourierTransform) :: hfft
        integer(ip) :: m, n, n2, k, l
        real(wp) :: r(m, n), wsav(*), work(*), r2km2, r2km1
        n2 = (n+1)/2
        !
        !     compute fourier coefficients for r on shifted grid
        !
        call hfft%forward(m, n, r, m, wsav(n+2), work)
        do l=1, m
            do k=2, n2
                r2km2 = r(l, k+k-2)
                r2km1 = r(l, k+k-1)
                r(l, k+k-2)   =  r2km2*wsav(n2+k) - r2km1*wsav(k)
                r(l, k+k-1)   =  r2km2*wsav(k)    + r2km1*wsav(n2+k)
            end do
        end do
        !     shift r with fourier synthesis and normalization
        !
        call hfft%backward(m, n, r, m, wsav(n+2), work)
        do l=1, m
            do k=1, n
                r(l, k) = r(l, k)/n
            end do
        end do

    end subroutine shifth

    subroutine shifthi(n, dp, wsav)
        !
        !     initialize wsav for subroutine shifth
        !

        type(RealPeriodicFastFourierTransform) :: hfft
        integer(ip) :: n, n2, k
        real(wp) :: wsav(*), dp
        n2 = (n+1)/2
        do k=2, n2
            wsav(k)    =  sin((k-1)*dp)
            wsav(k+n2) =  cos((k-1)*dp)
        end do
        call hfft%initialize(n, wsav(n+2))

    end subroutine shifthi

end module module_sshifte
