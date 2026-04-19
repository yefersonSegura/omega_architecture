import type { Theme } from 'vitepress';
import DefaultTheme from 'vitepress/theme';
import OmegaObservabilityDashboard from './components/OmegaObservabilityDashboard.vue';
import './omega-presentation.css';

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('OmegaObservabilityDashboard', OmegaObservabilityDashboard);
  },
} satisfies Theme;
