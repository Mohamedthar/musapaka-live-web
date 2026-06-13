'use client';

import Image from 'next/image';
import { motion } from 'framer-motion';

interface HeroBackgroundProps {
  /** CSS class for GSAP parallax targeting, e.g. "hero-bg-image" */
  parallaxClass?: string;
  /** Fade-in duration in seconds */
  fadeDuration?: number;
}

export default function HeroBackground({ parallaxClass, fadeDuration = 2 }: HeroBackgroundProps) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 1.05 }}
      animate={{ opacity: 0.55, scale: 1 }}
      transition={{ duration: fadeDuration, ease: 'easeOut' }}
      className={`absolute inset-0 z-[1] ${parallaxClass ?? ''}`}
    >
      <Image
        src="/background.png"
        alt=""
        fill
        priority
        fetchPriority="high"
        sizes="100vw"
        className="object-cover"
        style={{ objectPosition: 'center 40%' }}
        quality={85}
      />
      <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-primary/60" />
    </motion.div>
  );
}
