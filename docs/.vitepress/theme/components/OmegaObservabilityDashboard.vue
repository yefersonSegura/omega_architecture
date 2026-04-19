<script setup lang="ts">
import { computed } from 'vue';
import { useData } from 'vitepress';

const props = withDefaults(
  defineProps<{
    /** When set, wraps the image in a link to the observability guide */
    linkToGuide?: boolean;
  }>(),
  { linkToGuide: false },
);

const { site } = useData();

const assetSrc = computed(() => {
  const base = site.value.base;
  const path = 'omega-observability-dashboard.svg';
  return base.endsWith('/') ? `${base}${path}` : `${base}/${path}`;
});

const guideHref = computed(() => {
  const base = site.value.base;
  const path = 'guide/observability-and-stats.html';
  return base.endsWith('/') ? `${base}${path}` : `${base}/${path}`;
});

const alt =
  'Example statistical dashboard: channel events by category, intent to expression latency, events per minute, and flow snapshot';
</script>

<template>
  <div class="omega-obs-dash">
    <a v-if="linkToGuide" class="omega-obs-dash__frame" :href="guideHref" title="Observability and statistics guide">
      <img class="omega-obs-dash__img" :src="assetSrc" :alt="alt" width="820" height="473" loading="lazy" decoding="async" />
    </a>
    <div v-else class="omega-obs-dash__frame">
      <img class="omega-obs-dash__img" :src="assetSrc" :alt="alt" width="820" height="473" loading="lazy" decoding="async" />
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
.omega-obs-dash__img {
  display: block;
  width: 100%;
  max-width: 820px;
  height: auto;
}
</style>
