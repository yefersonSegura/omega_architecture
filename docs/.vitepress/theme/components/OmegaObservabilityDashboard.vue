<script setup lang="ts">
import { computed } from 'vue';
import { useData } from 'vitepress';
// Bundled at build time — no runtime URL / base-path issues (fixes broken <img> on some hosts).
import dashboardSvg from '../../../public/omega-observability-dashboard.svg?raw';

withDefaults(
  defineProps<{
    /** When set, wraps the chart in a link to the observability guide */
    linkToGuide?: boolean;
  }>(),
  { linkToGuide: false },
);

const { site } = useData();

const guideHref = computed(() => {
  const base = site.value.base ?? '/';
  const normalized = base.endsWith('/') ? base : `${base}/`;
  return `${normalized}guide/observability-and-stats.html`;
});

const ariaLabel =
  'Example statistical dashboard: channel events by category, intent to expression latency, events per minute, and flow snapshot';
</script>

<template>
  <div class="omega-obs-dash">
    <a
      v-if="linkToGuide"
      class="omega-obs-dash__frame"
      :href="guideHref"
      title="Observability and statistics guide"
    >
      <span class="omega-obs-dash__svg-root" v-html="dashboardSvg" role="img" :aria-label="ariaLabel" />
    </a>
    <div v-else class="omega-obs-dash__frame">
      <span class="omega-obs-dash__svg-root" v-html="dashboardSvg" role="img" :aria-label="ariaLabel" />
    </div>
  </div>
</template>

<style scoped>
.omega-obs-dash {
  text-align: center;
  margin: 0.5rem 0 2rem;
}
.omega-obs-dash__frame {
  display: inline-block;
  max-width: 100%;
  border-radius: 14px;
  border: 1px solid var(--vp-c-divider);
  box-shadow: 0 8px 30px rgba(15, 23, 42, 0.06);
  overflow: hidden;
  line-height: 0;
}
.omega-obs-dash__frame:is(a) {
  transition: box-shadow 0.15s ease, transform 0.15s ease;
}
.omega-obs-dash__frame:is(a):hover {
  box-shadow: 0 12px 36px rgba(15, 23, 42, 0.1);
  transform: translateY(-1px);
}
.omega-obs-dash__svg-root :deep(svg) {
  display: block;
  width: 100%;
  max-width: 820px;
  height: auto;
  vertical-align: top;
}
</style>
