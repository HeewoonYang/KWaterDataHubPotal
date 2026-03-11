/**
 * Vue Router 설정
 */
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: () => import('@/views/MainLayout.vue'),
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: { title: '대시보드' },
        },
        {
          path: 'words',
          name: 'words',
          component: () => import('@/views/WordDictView.vue'),
          meta: { title: '단어사전' },
        },
        {
          path: 'domain-groups',
          name: 'domain-groups',
          component: () => import('@/views/DomainGroupView.vue'),
          meta: { title: '도메인그룹' },
        },
        {
          path: 'domains',
          name: 'domains',
          component: () => import('@/views/DomainDictView.vue'),
          meta: { title: '도메인사전' },
        },
        {
          path: 'terms',
          name: 'terms',
          component: () => import('@/views/TermDictView.vue'),
          meta: { title: '용어사전' },
        },
        {
          path: 'code-groups',
          name: 'code-groups',
          component: () => import('@/views/CodeGroupView.vue'),
          meta: { title: '코드그룹' },
        },
        {
          path: 'codes',
          name: 'codes',
          component: () => import('@/views/CodeDictView.vue'),
          meta: { title: '코드사전' },
        },
        {
          path: 'import-export',
          name: 'import-export',
          component: () => import('@/views/ImportExportView.vue'),
          meta: { title: '임포트/엑스포트' },
        },
        {
          path: 'history',
          name: 'history',
          component: () => import('@/views/HistoryView.vue'),
          meta: { title: '변경이력' },
        },
      ],
    },
  ],
})

// 페이지 타이틀 설정
router.afterEach((to) => {
  const title = (to.meta?.title as string) || '메타데이터 표준사전'
  document.title = `${title} — K-water 메타데이터`
})

export default router
