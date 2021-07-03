module.exports = function(api) {
    api.cache.using(() => process.env.NODE_ENV);

    const presets = [
        "@babel/env",
        "@babel/preset-react",
        "@babel/preset-typescript",
    ];
    const plugins = [];

    return { presets, plugins };
};
