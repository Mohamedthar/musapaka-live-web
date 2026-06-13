import Image from 'next/image';

interface HeroBackgroundProps {
  /** CSS class for GSAP parallax targeting, e.g. "hero-bg-image" */
  parallaxClass?: string;
}

export default function HeroBackground({ parallaxClass }: HeroBackgroundProps) {
  return (
    <div className={`absolute inset-0 z-[1] ${parallaxClass ?? ''}`} style={{ opacity: 0.55 }}>
      <Image
        src="/background.png"
        alt=""
        fill
        priority
        fetchPriority="high"
        sizes="100vw"
        className="object-cover"
        style={{ objectPosition: 'center 40%' }}
        quality={75}
      />
      <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-primary/60" />
    </div>
  );
}
