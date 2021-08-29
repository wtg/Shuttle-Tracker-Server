function configureTheme() {
	const prefersDarkMode = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
	const bootstrapDarkmode = window['bootstrap-darkmode']
	const themeConfig = new bootstrapDarkmode.ThemeConfig()
	themeConfig.loadTheme = () => {
		return prefersDarkMode ? "dark" : "light"
	};
	themeConfig.initTheme()
}
