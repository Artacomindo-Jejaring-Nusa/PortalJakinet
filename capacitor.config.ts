import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.jakinet.portal',
  appName: 'Portal Jakinet',
  webDir: 'out',
  server: {
    url: 'https://portal.ajnusa.com/login',
    cleartext: true,
    androidScheme: 'https'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 3000,
      launchAutoHide: true,
      backgroundColor: "#ffffff",
      showSpinner: true,
      androidSpinnerStyle: "large",
      spinnerColor: "#ED3B3B" // Warna merah khas Jakinet
    }
  }
};

export default config;
