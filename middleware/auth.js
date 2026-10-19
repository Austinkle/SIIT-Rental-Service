function requireRole(...roles){
    return (req, res, next) => {
        const user = req.session.user;
        const isApi = req.originalUrl.includes('/api/');

        if(!user){
            return isApi ? res.status(401).json({error: 'Please log in'})
                         : res.redirect('/login.html')
        }

        if(!roles.includes(user.role)){
            return isApi ? res.status(403).json({error: 'Not Allowes'})
                         : res.status(403).send('Not allowed');
        }
        next();
    };
}

module.exports = { requireRole };